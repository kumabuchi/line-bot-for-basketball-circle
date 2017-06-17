class Webhook
  def cheer(param)
    image_name = File.basename(Dir.glob("#{ROOT_DIR}/webroot/static/slamdunk/*.png").sample)
    send_msg_obj = Message.create_image_obj("#{Settings.base_url}static/slamdunk/#{image_name}")
    LineApi.reply(param[:replyToken], send_msg_obj)
  end

  def say(param)
    serif = YAML.load_file("#{ROOT_DIR}/config/yaml/serif.yml").sample
    send_msg_obj = Message.create_text_obj(serif)
    LineApi.reply(param[:replyToken], send_msg_obj)
  end

  def game(param)
    games = Games.create_games_message_obj
    LineApi.reply(param[:replyToken], games)
  end

  def sticker_response(param, sticker_id, package_id)
    send_msg_obj = Message.create_sticker_obj(sticker_id, package_id)
    LineApi.reply(param[:replyToken], send_msg_obj)
  end

  def qr(param)
    msg = param[:message][:text]
    image_url = QrCode.new.create(msg[3...msg.length].strip)
    send_msg_obj = Message.create_image_obj(image_url)
    LineApi.reply(param[:replyToken], send_msg_obj)
  rescue => e
    erb = File.read("#{ROOT_DIR}/lib/views/message/qr_error.erb")
    send_msg_obj = Message.create_text_obj(ERB.new(erb, nil, '-').result(binding))
    LineApi.reply(param[:replyToken], send_msg_obj)
  end

  def team(param)
    members = param[:message][:text].split[1..-1]
    if members.nil? || members.length < 1
      erb = File.read("#{ROOT_DIR}/lib/views/message/team_usage.erb")
      send_msg_obj = Message.create_text_obj(ERB.new(erb, nil, '-').result(binding))
      LineApi.reply(param[:replyToken], send_msg_obj)
    else
      teams = Member.team(2, members)
      erb = File.read("#{ROOT_DIR}/lib/views/message/team.erb")
      send_msg_obj = Message.create_text_obj(ERB.new(erb, nil, '-').result(binding))
      LineApi.reply(param[:replyToken], send_msg_obj)
    end
  end

  def member(param)
    members = param[:message][:text].split[1..-1]
    if members.nil? || members.length < 1
      erb = File.read("#{ROOT_DIR}/lib/views/message/member_usage.erb")
      send_msg_obj = Message.create_text_obj(ERB.new(erb, nil, '-').result(binding))
      LineApi.reply(param[:replyToken], send_msg_obj)
    else
      selected_members = Member.random(1, members)
      erb = File.read("#{ROOT_DIR}/lib/views/message/member.erb")
      send_msg_obj = Message.create_text_obj(ERB.new(erb, nil, '-').result(binding))
      LineApi.reply(param[:replyToken], send_msg_obj)
    end
  end

  def sportsone(param, level)
    xml = HTTParty.get(Settings.url.sportsone, :format => :xml)
    erb = File.read("#{ROOT_DIR}/lib/views/message/sportsone.erb")
    send_msg_obj = Message.create_text_obj(ERB.new(erb, nil, '-').result(binding))
    LineApi.reply(param[:replyToken], send_msg_obj)
  end

  def crystarea(param, level)
    class_id = case level
      when 'よち'    then 20
      when 'ぷち'    then 39
      when 'ぴよ'    then 9
      when 'わい'    then 10
      when 'よちMIX' then 21
      when 'ぷちMIX' then 40
      when 'ぴよMIX' then 16
    end
    html = HTTParty.get("#{Settings.url.crystarea}#{class_id}")
    erb = File.read("#{ROOT_DIR}/lib/views/message/crystarea.erb")
    send_msg_obj = Message.create_text_obj(ERB.new(erb, nil, '-').result(binding))
    LineApi.reply(param[:replyToken], send_msg_obj)
  end

  def calc(param)
    answer = Calculator.calc(param[:message][:text])
    erb = File.read("#{ROOT_DIR}/lib/views/message/calc.erb")
    send_msg_obj = Message.create_text_obj(ERB.new(erb, nil, '-').result(binding))
    LineApi.reply(param[:replyToken], send_msg_obj)
  end

  def participation(param)
    if param[:source][:groupId]
      erb = File.read("#{ROOT_DIR}/lib/views/message/participation_error.erb")
      send_msg_obj = Message.create_text_obj(ERB.new(erb, nil, '-').result(binding))
      LineApi.reply(param[:replyToken], send_msg_obj)
    else
      user = User.find_by(line_user_id: param[:source][:userId])
      raise Settings.error.db_inconsistency unless user
      erb = File.read("#{ROOT_DIR}/lib/views/message/participation.erb")
      send_msg_obj = Message.create_text_obj(ERB.new(erb, nil, '-').result(binding))
      LineApi.reply(param[:replyToken], send_msg_obj)
    end
  end

  def generate_random_hash(param)
    if param[:source][:groupId]
      erb = File.read("#{ROOT_DIR}/lib/views/message/generate_random_hash_error.erb")
      send_msg_obj = Message.create_text_obj(ERB.new(erb, nil, '-').result(binding))
      LineApi.reply(param[:replyToken], send_msg_obj)
    else
      user = User.find_by(line_user_id: param[:source][:userId])
      raise Settings.error.db_inconsistency unless user
      user.random = User.generate_random(50)
      user.save!
      erb = File.read("#{ROOT_DIR}/lib/views/message/generate_random_hash.erb")
      send_msg_obj = Message.create_text_obj(ERB.new(erb, nil, '-').result(binding))
      LineApi.reply(param[:replyToken], send_msg_obj)
    end
  end

  def setting(param)
    if param[:source][:groupId]
      erb = File.read("#{ROOT_DIR}/lib/views/message/setting_error.erb")
      send_msg_obj = Message.create_text_obj(ERB.new(erb, nil, '-').result(binding))
      LineApi.reply(param[:replyToken], send_msg_obj)
    else
      user = User.find_by(line_user_id: param[:source][:userId])
      raise Settings.error.db_inconsistency unless user
      erb = File.read("#{ROOT_DIR}/lib/views/message/setting.erb")
      send_msg_obj = Message.create_text_obj(ERB.new(erb, nil, '-').result(binding))
      LineApi.reply(param[:replyToken], send_msg_obj)
    end
  end

  def set_remind(param, value)
    if param[:source][:groupId]
      erb = File.read("#{ROOT_DIR}/lib/views/message/set_remind_error.erb")
      send_msg_obj = Message.create_text_obj(ERB.new(erb, nil, '-').result(binding))
      LineApi.reply(param[:replyToken], send_msg_obj)
    else
      user = User.find_by(line_user_id: param[:source][:userId])
      raise Settings.error.db_inconsistency unless user
      user.remind = value
      user.save!
      erb = File.read("#{ROOT_DIR}/lib/views/message/set_remind.erb")
      send_msg_obj = Message.create_text_obj(ERB.new(erb, nil, '-').result(binding))
      LineApi.reply(param[:replyToken], send_msg_obj)
    end
  end

  def set_request(param, value)
    if param[:source][:groupId]
      erb = File.read("#{ROOT_DIR}/lib/views/message/set_request_error.erb")
      send_msg_obj = Message.create_text_obj(ERB.new(erb, nil, '-').result(binding))
      LineApi.reply(param[:replyToken], send_msg_obj)
    else
      user = User.find_by(line_user_id: param[:source][:userId])
      raise Settings.error.db_inconsistency unless user
      user.request = value
      user.save!
      erb = File.read("#{ROOT_DIR}/lib/views/message/set_request.erb")
      send_msg_obj = Message.create_text_obj(ERB.new(erb, nil, '-').result(binding))
      LineApi.reply(param[:replyToken], send_msg_obj)
    end
  end

  def schedule(param)
    erb = File.read("#{ROOT_DIR}/lib/views/message/schedule.erb")
    send_msg_obj = Message.create_text_obj(ERB.new(erb, nil, '-').result(binding))
    LineApi.reply(param[:replyToken], send_msg_obj)
  end

  def movie(param)
    erb = File.read("#{ROOT_DIR}/lib/views/message/movie.erb")
    send_msg_obj = Message.create_text_obj(ERB.new(erb, nil, '-').result(binding))
    LineApi.reply(param[:replyToken], send_msg_obj)
  end

  def update(param)
    if param[:source][:groupId]
      erb = File.read("#{ROOT_DIR}/lib/views/message/update_error.erb")
      send_msg_obj = Message.create_text_obj(ERB.new(erb, nil, '-').result(binding))
      LineApi.reply(param[:replyToken], send_msg_obj)
    else
      user = User.find_by(line_user_id: param[:source][:userId])
      raise Settings.error.db_inconsistency unless user
      profile = LineApi.profile(param[:source][:userId]);
      user.name = profile[:displayName]
      user.profile_image_url = profile[:pictureUrl]
      user.save!
      erb = File.read("#{ROOT_DIR}/lib/views/message/update.erb")
      send_msg_obj = Message.create_text_obj(ERB.new(erb, nil, '-').result(binding))
      LineApi.reply(param[:replyToken], send_msg_obj)
    end
  end

  def add_reservation(param)
    responses = GoogleCalendar.new.add_reservation(param[:message][:text])
    erb = responses.empty? ?
      File.read("#{ROOT_DIR}/lib/views/message/add_reservation_error.erb") :
      File.read("#{ROOT_DIR}/lib/views/message/add_reservation.erb")
    send_msg_obj = Message.create_text_obj(ERB.new(erb, nil, '-').result(binding))
    LineApi.reply(param[:replyToken], send_msg_obj)
  end

  def summary(param)
    schedules = Schedule.in_future.not_cancelled.not_personal_practice.order_by_start
    erb = File.read("#{ROOT_DIR}/lib/views/message/summary_webhook.erb")
    send_msg_obj = Message.create_text_obj(ERB.new(erb, nil, '-').result(binding))
    LineApi.reply(param[:replyToken], send_msg_obj)
  end

  def start_dialogue(param, msg, source_id)
    FileUtils.touch("#{ROOT_DIR}/tmp/dialogue/#{source_id}")
    erb = File.read("#{ROOT_DIR}/lib/views/message/start_dialogue.erb")
    send_msg_obj = Message.create_text_obj(ERB.new(erb, nil, '-').result(binding))
    LineApi.reply(param[:replyToken], send_msg_obj)
  end

  def finish_dialogue(param, msg, source_id)
    FileUtils.rm("#{ROOT_DIR}/tmp/dialogue/#{source_id}")
    erb = File.read("#{ROOT_DIR}/lib/views/message/finish_dialogue.erb")
    send_msg_obj = Message.create_text_obj(ERB.new(erb, nil, '-').result(binding))
    LineApi.reply(param[:replyToken], send_msg_obj)
  end

  def dialogue(param, msg, source_id)
    context = File.read("#{ROOT_DIR}/tmp/dialogue/#{source_id}")
    response = HTTParty.post(
      "https://api.apigw.smt.docomo.ne.jp/dialogue/v1/dialogue?APIKEY=#{Settings.docomo.dialogue.api_key}",
      :body    => { :utt     => "#{msg.inspect}",
                    :context => "#{context.strip}"
                  }.to_json,
      :headers => { 'Content-Type' => 'application/json',
                    'Accept'       => 'application/json' }
    )
    File.write("#{ROOT_DIR}/tmp/dialogue/#{source_id}", response['context'])
    send_msg_obj = Message.create_text_obj("#{response['utt']}")
    LineApi.reply(param[:replyToken], send_msg_obj)
  end

  def follow(param)
    profile = LineApi.profile(param[:source][:userId]);
    user = User.find_or_create_by(line_user_id: profile[:userId])
    user.name = profile[:displayName]
    user.profile_image_url = profile[:pictureUrl]
    user.random = User.generate_random(50)
    user.remind = true
    user.request = true
    user.save!
  end

  def unfollow(param)
    user = User.find_by(line_user_id: param[:source][:userId])
    return unless user
    Participation.where(user_id: user.id).delete_all
    user.destroy!
  end

  def help(param)
    erb = File.read("#{ROOT_DIR}/lib/views/message/help.erb")
    send_msg_obj = Message.create_text_obj(ERB.new(erb, nil, '-').result(binding))
    LineApi.reply(param[:replyToken], send_msg_obj)
  end
end
