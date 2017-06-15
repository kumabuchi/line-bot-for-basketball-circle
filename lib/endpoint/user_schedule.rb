class UserSchedule
  def schedule
    Schedule.in_future.not_cancelled.not_personal_practice.order_by_start
  end

  def summary
    schedules = Schedule.in_future.not_cancelled.not_personal_practice.not_foo_fighters_practice.order_by_start
    response_message = ["直近5日以内の予約で参加人数が3人以下の日があります。キャンセル忘れに注意してください。"]
    require_notice = false
    schedules.each do |schedule|
      break if schedule.start >= (Time.now + 5.day).beginning_of_day
      if schedule.count_ok <= 3
        response_message.push('-------------------')
        response_message.push("#{schedule.date_ja(true)}")
        response_message.push("#{schedule.description}")
        response_message.push("〇#{schedule.count_ok} △#{schedule.count_un} ×#{schedule.count_ko}")
        require_notice = true
      end
    end
    return unless require_notice
    send_msg_obj = Message.create_text_obj(response_message.join("\n"))
    Settings.admin_users.each do |admin_user|
      LineApi.push(admin_user, send_msg_obj)
    end
  end

  def sync
    events = GoogleCalendar.new.list
    Schedule.update_all("is_cancelled = 1")
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
      response_message = [
        '【予約追加】',
        schedule.date_ja(true),
        schedule.description,
        'http://qq4q.biz/yIFs'
      ].join("\n")
      send_msg_obj = Message.create_text_obj(response_message)
      LineApi.push(Settings.group_id, send_msg_obj)
    end

    # bug: 削除済みアカウントのprofileは404
    User.all.each do |user|
      profile = LineApi.profile(user.line_user_id);
      next if profile.nil?
      user.name = profile[:displayName]
      user.profile_image_url = profile[:pictureUrl].nil? ? "#{Settings.base_url}static/images/default.jpg" : profile[:pictureUrl]
      user.save!
    end
  end

  def remind
    tomorrow_schedules = Schedule.not_cancelled.in_tomorrow.order_by_start
    tomorrow_schedules.each do |schedule|
      response_message = [
        '【リマインダー】',
        schedule.date_ja(true),
        schedule.description,
        'http://qq4q.biz/yIFs'
      ].join("\n")
      send_msg_obj = Message.create_text_obj(response_message)
      LineApi.push(Settings.group_id, send_msg_obj)
      
      participants = Participation.in_schedule(schedule.id).participant
      participants.each do |participant|
        user = User.find_by(id: participant.user_id, remind: true)
        next unless user
        response_message = [
          '【リマインダー】',
          "#{user.name}さんは明日参加予定です。",
          "---------------",
          schedule.date_ja(true),
          schedule.description,
          'http://qq4q.biz/yIFs'
        ].join("\n")
        send_msg_obj = Message.create_text_obj(response_message)
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
        if participation.nil? || participation.propriety == 0
          message = [
            '【リクエスト】',
            "1週間以内に開催予定のイベントの参加可否が未登録もしくは△になっています。以下のURLからアクセスして〇or×の登録をお願いします。",
            "#{Settings.base_url}schedule/#{user.random}"
          ].join("\n")
          send_msg_obj = Message.create_text_obj(message)
          LineApi.push(user.line_user_id, send_msg_obj)
          break
        end
      end
    end 
  end

  def personal_schedule(random_hash)
    @user = User.find_by(random: random_hash)
    raise 'ユーザが見つかりませんでした。' unless @user
    @schedules = Schedule.in_future.not_cancelled.not_personal_practice.order_by_start
    [@user, @schedules]
  end

  def update(random_hash, params)
    user = User.find_by(random: random_hash)
    raise 'ユーザが見つかりませんでした' unless user
    message = ["#{user.name}さんが以下の直近開催イベントの参加表を〇から× or △に変更したようです。。"]
    require_notice = false
    params.each do |id, val|
      schedule = Schedule.find_by_id(id)
      if schedule
        participation = Participation.find_or_create_by(user_id: user.id, schedule_id: id)
        if schedule.start < (Time.now + 3.day).beginning_of_day && participation.propriety == 1 && val != 'ok'
          message.push('-------------------')
          message.push("#{schedule.date_ja(true)}")
          message.push("#{schedule.description}")
          require_notice = true
        end
        participation.propriety = case val
          when 'ko' then -1
          when 'un' then 0
          when 'ok' then 1
        end
        participation.save!
      end
    end
    return unless require_notice
    send_msg_obj = Message.create_text_obj(message.join("\n"))
    Settings.admin_users.each do |admin_user|
      LineApi.push(admin_user, send_msg_obj)
    end
  end
end
