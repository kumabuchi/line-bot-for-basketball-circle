class Controller < Sinatra::Base

  set :show_exceptions, false

  before do
    @logger = Logger.new('log/sinatra.log')
    http_headers = request.env.select { |k, v| k.start_with?('HTTP_') }
    @logger.info(http_headers)
  end

  not_found do
    status 404
    @message = 'ファイルが見つかりませんでした。'
    erb :error_404, layout: false
  end

  error do |e|
    status 500
    @message = e.message
    @logger.error("#{e.message}")
    send_msg_obj = Message.create_text_obj("ERROR: #{e.message}")
    LineApi.push(ENV['ADMIN_USER'], send_msg_obj)
    erb :error_500, layout: false
  end

  get '/schedule/sync' do
    UserSchedule.new.sync
    @status = 'OK'
    @message = ''
    erb :rest, layout: false
  end

  get '/schedule/remind' do
    UserSchedule.new.remind
    @status = 'OK'
    @message = ''
    erb :rest, layout: false
  end

  get '/schedule/request' do
    UserSchedule.new.request
    @status = 'OK'
    @message = ''
    erb :rest, layout: false
  end

  get '/schedule' do
    @schedules = UserSchedule.new.schedule
    erb :schedule
  end

  get '/schedule/:random_hash' do |random_hash|
    @user, @schedules = UserSchedule.new.personal_schedule(random_hash)
    @load_js_mgm = true
    erb :personal_schedule
  end

  post '/schedule/:random_hash' do |random_hash|
    UserSchedule.new.update(random_hash, @params)
    redirect to('/schedule')
  end

  post '/webhook' do
    params = JSON.parse(request.body.read, symbolize_names: true)
    @logger.info(params)
   
    params[:events].each do |param|
      break if !param[:source][:groupId].nil? && param[:source][:groupId] != ENV['GROUP_ID']

      if param[:type] == 'follow'
        Webhook.new.follow(param)
      end
      if param[:type] == 'unfollow'
        Webhook.new.unfollow(param)
      end
      if param[:type] == 'message'
        msg = param[:message][:text]
        next if msg.nil?
        if msg.include?('画像')
          Webhook.new.cheer(param)
        elsif msg.include?('名言')
          Webhook.new.say(param)
        elsif msg.include?('ドタ参')
          Webhook.new.sticker_response(param, '114', '1')
        elsif msg.include?('全面')
          Webhook.new.sticker_response(param, '19', '2')
        elsif msg.include?('遅刻') || msg.include?('遅れ')
          Webhook.new.sticker_response(param, '520', '2')
        elsif msg.include?('キャンセルします') || msg.include?('キャンセルしまーす')
          Webhook.new.sticker_response(param, '16', '1')
        elsif msg.include?('出勤') || msg.include?('仕事')
          Webhook.new.sticker_response(param, '161', '2')
        elsif msg.downcase.start_with?('qr:')
          Webhook.new.qr(param)
        elsif msg.downcase.start_with?('チーム分け') || msg.downcase.start_with?('チームわけ')
          Webhook.new.team(param)
        elsif msg.downcase.start_with?('抽選')
          Webhook.new.member(param)
        elsif /超初級|初級|初中級|中級/ =~ msg
          Webhook.new.competition(param, msg)
        elsif msg == '参加可否'
          Webhook.new.participation(param)
        elsif msg == '参加表'
          Webhook.new.schedule(param)
        elsif msg == 'URL変更'
          Webhook.new.generate_random_hash(param)
        elsif msg == '更新'
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
        elsif msg == 'プレイ動画'
          Webhook.new.movie(param)
        elsif msg.match(/^([0-9\+\-\*\/\(\)\%\^\.\:]+)$/)
          Webhook.new.calc(param)
        end 
      end
    end 
    @status = 'OK'
    @message = ''
    erb :rest, layout: false
  end
end
