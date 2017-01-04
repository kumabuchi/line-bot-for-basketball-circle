class UserSchedule
  def schedule
    Schedule.in_future.not_cancelled.not_personal_practice.order_by_start
  end

  def sync
    events = GoogleCalendar.new.list
    Schedule.update_all("is_cancelled = 1")
    new_schedules = []
    events.each do |event|
      start_date = event.start.date || event.start.date_time
      end_date = event.end.date || event.end.date_time
      schedule = Schedule.find_or_initialize_by(start: start_date, end: end_date)
      new_schedules.push(schedule) if schedule.new_record?
      schedule.description = event.summary
      schedule.is_cancelled = event.summary.include?('キャンセル')
      schedule.save!
    end
    new_schedules.each do |schedule|
      response_message = [
        '【予約追加】',
        schedule.description,
        schedule.date_ja(true),
        'http://qq4q.biz/yIFs'
      ].join("\n")
      send_msg_obj = Message.create_text_obj(response_message)
      LineApi.push(ENV['GROUP_ID'], send_msg_obj)
    end
  end

  def remind
    tomorrow_schedules = Schedule.not_cancelled.in_tomorrow.order_by_start
    tomorrow_schedules.each do |schedule|
      response_message = [
        '【リマインダー】',
        schedule.description,
        schedule.date_ja(true),
        'http://qq4q.biz/yIFs'
      ].join("\n")
      send_msg_obj = Message.create_text_obj(response_message)
      LineApi.push(ENV['GROUP_ID'], send_msg_obj)
      
      participants = Participation.in_schedule(schedule.id).participant
      participants.each do |participant|
        user = User.find_by(id: participant.user_id, remind: true)
        next unless user
        response_message = [
          '【リマインダー】',
          "#{user.name}さんは明日参加予定です。",
          "---------------",
          schedule.description,
          schedule.date_ja(true),
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
            "1週間以内に開催予定のイベントについて、参加可否が未登録もしくは△になっています。以下のURLからアクセスして〇or×の登録をお願いします。",
            "#{BASE_URL}schedule/#{user.random}"
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
    params.each do |id, val|
      if Schedule.find_by_id(id)
        p = Participation.find_or_create_by(user_id: user.id, schedule_id: id)
        p.propriety = case val
          when 'ko' then -1
          when 'un' then 0
          when 'ok' then 1
        end
        p.save!
      end
    end
  end
end
