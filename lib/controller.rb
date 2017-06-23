class Controller < Sinatra::Base

  set :show_exceptions, false

  before do
    @logger = Logger.new('log/sinatra.log')
  end

  not_found do
    status 404
    erb :'html/error_404', layout: false
  end

  error do |e|
    status 500
    @message = e.message
    @logger.error("#{e.message}")
    e_erb = File.read("#{ROOT_DIR}/lib/views/message/error.erb")
    send_msg_obj = Message.create_text_obj(ERB.new(e_erb, nil, '-').result(binding))
    Settings.admin_users.each do |admin_user|
      LineApi.push(admin_user, send_msg_obj)
    end
    erb :'html/error_500', layout: false
  end

  get '/schedule/remind' do
    UserSchedule.new.remind
    erb :'rest/status_and_message', layout: false
  end

  get '/schedule/request' do
    UserSchedule.new.request
    erb :'rest/status_and_message', layout: false
  end

  get '/schedule/summary' do
    UserSchedule.new.summary
    erb :'rest/status_and_message', layout: false
  end

  get '/schedule/sync' do
    UserSchedule.new.sync
    erb :'rest/status_and_message', layout: false
  end

  get '/schedule' do
    @schedules = UserSchedule.new.schedule
    erb :'html/schedule'
  end

  get '/schedule/:random_hash' do |random_hash|
    @user, @schedules = UserSchedule.new.personal_schedule(random_hash)
    erb :'html/personal_schedule'
  end

  post '/schedule/:random_hash' do |random_hash|
    @logger.info(@params)
    UserSchedule.new.update(random_hash, @params)
    redirect to('/schedule')
  end

  post '/webhook' do
    params = JSON.parse(request.body.read, symbolize_names: true)
    @logger.info(params)
   
    params[:events].each do |param|
      break if !param[:source][:groupId].nil? && param[:source][:groupId] != Settings.group_id
      source_id = param[:source][:groupId].nil? ? param[:source][:userId] : param[:source][:groupId]

      if param[:type] == 'follow'
        Webhook.new.follow(param)
      end
      if param[:type] == 'unfollow'
        Webhook.new.unfollow(param)
      end
      if param[:type] == 'message'
        msg = param[:message][:text]
        next if msg.nil?

        if msg == '参加表'
          Webhook.new.schedule(param)
        elsif msg == '参加可否'
          Webhook.new.participation(param)
        elsif msg == 'URL変更'
          Webhook.new.generate_random_hash(param)
        elsif msg == 'ユーザ情報更新'
          Webhook.new.update(param)
        elsif msg == '通知設定'
          Webhook.new.setting(param)
        elsif msg == 'リマインドオン'
          Webhook.new.set_remind(param, true)
        elsif msg == 'リマインドオフ'
          Webhook.new.set_remind(param, false)
        elsif msg == 'リクエストオン'
          Webhook.new.set_request(param, true)
        elsif msg == 'リクエストオフ'
          Webhook.new.set_request(param, false)
        elsif msg == 'ヘルプ'
          Webhook.new.help(param)
        elsif msg == '動画URL'
          Webhook.new.movie(param)
        elsif msg == 'ゲーム'
          Webhook.new.game(param)
        elsif msg == 'サマリ' || msg == 'サマリー'
          Webhook.new.summary(param)
        elsif /^予約申込の完了/ =~ msg
          Webhook.new.add_reservation(param)
        elsif msg.match(/^([0-9\+\-\*\/\(\)\%\^\.\:]+)$/)
          Webhook.new.calc(param)
        elsif /^超初級$|^初級$|^初中級$|^中級$/ =~ msg
          Webhook.new.sportsone(param, msg)
        elsif /^よち$|^ぷち$|^ぴよ$|^わい$|^よちMIX$|^ぷちMIX$|^ぴよMIX$/ =~ msg
          Webhook.new.crystarea(param, msg)
        elsif msg.downcase.start_with?('qr:')
          Webhook.new.qr(param)
        elsif msg.downcase.start_with?('抽選')
          Webhook.new.member(param)
        elsif msg.downcase.start_with?('チーム分け') || msg.downcase.start_with?('チームわけ')
          Webhook.new.team(param)
        elsif msg.include?('画像')
          Webhook.new.cheer(param)
        elsif msg.include?('名言')
          Webhook.new.say(param)
        elsif msg.include?('全面')
          Webhook.new.sticker_response(param, '19', '2')
        elsif msg.include?('ドタ参')
          Webhook.new.sticker_response(param, '114', '1')
        elsif msg.include?('遅刻') || msg.include?('遅れ')
          Webhook.new.sticker_response(param, '520', '2')
        elsif msg.include?('出勤') || msg.include?('仕事')
          Webhook.new.sticker_response(param, '161', '2')
        elsif msg.include?('キャンセルします') || msg.include?('キャンセルしまーす')
          Webhook.new.sticker_response(param, '16', '1')
        else
          next if source_id.nil? || msg.blank?
          if param[:source][:groupId].nil?
            Webhook.new.dialogue(param, msg)
          elsif (msg == 'こんにちは' || msg == 'こんばんは' || msg == 'おはよう') && !File.exist?("#{ROOT_DIR}/tmp/dialogue/#{source_id}")
            Webhook.new.start_dialogue(param, msg, source_id)
          elsif msg == 'さようなら' && File.exist?("#{ROOT_DIR}/tmp/dialogue/#{source_id}")
            Webhook.new.finish_dialogue(param, msg, source_id)
          elsif File.exist?("#{ROOT_DIR}/tmp/dialogue/#{source_id}")
            Webhook.new.dialogue(param, msg)
          end
        end
      end
    end 
    erb :'rest/status_and_message', layout: false
  end
end
