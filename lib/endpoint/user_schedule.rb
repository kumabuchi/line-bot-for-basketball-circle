class UserSchedule
  def schedule
    Schedule.in_future.not_cancelled.not_personal_practice.order_by_start
  end

  def summary
    schedules = Schedule.in_future.not_cancelled.not_personal_practice.not_foo_fighters_practice.order_by_start
    erb = ERB.new(File.read("#{ROOT_DIR}/lib/views/message/summary_user_schedule.erb"), nil, '-').result(binding)
    return unless erb.include?('-')
    send_msg_obj = Message.create_text_obj(erb)
    Settings.admin_users.each do |admin_user|
      LineApi.push(admin_user, send_msg_obj)
    end
    filename = Vbrowser.new.capture_reservation
    send_msg_obj = Message.create_image_obj("#{Settings.base_url}static/reservation/#{filename}")
    Settings.admin_users.each do |admin_user|
      LineApi.push(admin_user, send_msg_obj)
    end
  end

  def sync
    events = GoogleCalendar.new.list
    Schedule.update_cancel_all
    new_schedules = []
    events.each do |event|
      start_date = event.start.date || event.start.date_time
      end_date = event.end.date || event.end.date_time

      # 同じ時間の予約でも開始秒が異なる場合があるため、秒を切り捨てる
      start_date = start_date - Rational(start_date.sec, 24 * 60 * 60)
      end_date = end_date - Rational(end_date.sec, 24 * 60 * 60)

      schedule = Schedule.find_or_initialize_by(start: start_date, end: end_date)
      new_schedules.push(schedule) if schedule.new_record?
      schedule.description = event.summary
      schedule.is_cancelled = event.summary.include?('キャンセル')
      schedule.save!
    end
    new_schedules.each do |schedule|
      erb = File.read("#{ROOT_DIR}/lib/views/message/sync.erb")
      send_msg_obj = Message.create_text_obj(ERB.new(erb, nil, '-').result(binding))
      LineApi.push(Settings.group_id, send_msg_obj)
    end
  end

  def sync_profile
    User.all.each do |user|
      profile = LineApi.profile(user.line_user_id);
      next if profile.nil?
      user.name = profile[:displayName]
      if profile[:pictureUrl].nil?
        user.profile_image_url = "#{Settings.base_url}static/images/default.jpg"
      else
        `wget #{profile[:pictureUrl]} -O #{ROOT_DIR}/webroot/static/profiles/#{get_filename(profile[:pictureUrl])}`
        user.profile_image_url = "#{Settings.base_url}static/profiles/#{get_filename(profile[:pictureUrl])}"
      end
      user.save!
    end
  end

  def remind
    tomorrow_schedules = Schedule.not_cancelled.in_tomorrow.order_by_start
    tomorrow_schedules.each do |schedule|
      erb = File.read("#{ROOT_DIR}/lib/views/message/remind_group.erb")
      send_msg_obj = Message.create_text_obj(ERB.new(erb, nil, '-').result(binding))
      LineApi.push(Settings.group_id, send_msg_obj)
      
      participants = Participation.in_schedule(schedule.id).participant
      participants.each do |participant|
        user = User.find_by(id: participant.user_id, remind: true)
        next unless user
        erb = File.read("#{ROOT_DIR}/lib/views/message/remind_user.erb")
        send_msg_obj = Message.create_text_obj(ERB.new(erb, nil, '-').result(binding))
        LineApi.push(user.line_user_id, send_msg_obj)
      end
    end
  end

  def request
    schedules_in_week = Schedule.not_cancelled.not_personal_practice.in_week.order_by_start
    users = User.need_request
    users.each do |user|
      schedules_in_week.each do |schedule|
        participation = Participation.find_by(user_id: user.id, schedule_id: schedule.id)
        next unless participation.nil? || participation.propriety == 0
        erb = File.read("#{ROOT_DIR}/lib/views/message/request.erb")
        send_msg_obj = Message.create_text_obj(ERB.new(erb, nil, '-').result(binding))
        LineApi.push(user.line_user_id, send_msg_obj)
        break
      end
    end 
  end

  def personal_schedule(random_hash)
    user = User.find_by(random: random_hash)
    raise Settings.error.user_not_found unless user
    schedules = Schedule.in_future.not_cancelled.not_personal_practice.order_by_start
    [user, schedules]
  end

  def update(random_hash, params)
    user = User.find_by(random: random_hash)
    raise Settings.error.user_not_found unless user
    notice_schedules = []
    params.each do |id, val|
      schedule = Schedule.find_by_id(id)
      next unless schedule
      participation = Participation.find_or_create_by(user_id: user.id, schedule_id: id)
      propriety = Participation.convert_propriety(val)
      notice_schedules.push(schedule) if schedule.start < (Time.now + Settings.notice.update.day).beginning_of_day && participation.propriety == 1 && propriety != 1
      participation.propriety = propriety
      participation.save!
    end
    return if notice_schedules.empty?
    erb = File.read("#{ROOT_DIR}/lib/views/message/update_user_schedule.erb")
    send_msg_obj = Message.create_text_obj(ERB.new(erb, nil, '-').result(binding))
    LineApi.push(Settings.group_id, send_msg_obj)
  end

  def get_merge_src_and_dest(params)
    srcs = Schedule.not_personal_practice.order(start: :desc).limit(30)
    dests = Schedule.in_future.not_cancelled.not_personal_practice.order(start: :desc)
    src = dest = nil
    unless params.nil?
      params.each do |key, val|
        schedule = Schedule.find_by_id(val)
        next unless schedule
        src  = schedule if key == 'src'
        dest = schedule if key == 'dest'
      end
    end
    [srcs, dests, src, dest]
  end

  def merge(params)
    `cp #{ROOT_DIR}/config/db/basketball.db #{ROOT_DIR}/tmp/db/#{Time.now.strftime("%Y%m%d%H%M%S")}.db`
    src  = Schedule.find_by_id(params['src'])
    dest = Schedule.find_by_id(params['dest'])
    Participation.where(schedule_id: src.id).each do |p|
      next if Participation.where(schedule_id: dest.id).where(user_id: p.user_id).take
      participation = Participation.create(user_id: p.user_id, schedule_id: dest.id, propriety: p.propriety)
      participation.save! 
    end
  end

  private

  def get_filename(url)
    url =~ /([^\/]+?)([\?#].*)?$/
    $&
  end
end
