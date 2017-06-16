class Webhook
  def cheer(param)
    Dir.chdir("#{ROOT_DIR}/webroot/static/slamdunk") do 
      image_name = Dir.glob("*.png").sample
      send_msg_obj = Message.create_image_obj("#{Settings.base_url}static/slamdunk/#{image_name}")
      LineApi.reply(param[:replyToken], send_msg_obj)
    end
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
    text = msg[3...msg.length].strip
    image_url = QrCode.new.create(text)
    send_msg_obj = Message.create_image_obj(image_url)
    LineApi.reply(param[:replyToken], send_msg_obj)
  rescue => e
    send_msg_obj = Message.create_text_obj("QRコードに変換出来ませんでした。文字列が長すぎる可能性があります。")
    LineApi.reply(param[:replyToken], send_msg_obj)
  end

  def team(param)
    members = param[:message][:text].split
    members.shift
    if members.length < 1
      send_msg_obj = Message.create_text_obj("Usage: チーム分け [Usernames ..]\nex. チーム分け ユーザ1 ユーザ2 ユーザ3")
      LineApi.reply(param[:replyToken], send_msg_obj)
      return 
    end
    team_num = members.first.to_i == 0 ? 2 : members.shift.to_i
    teams = Member.team(team_num, members)
    response_message = ['以下のチーム分けでどうでしょう？']
    teams.each do |name, members|
      response_message.push("【#{name}】")
      response_message.push("#{members.sort.join(',')}")
    end
    send_msg_obj = Message.create_text_obj(response_message.join("\n"))
    LineApi.reply(param[:replyToken], send_msg_obj)
  end

  def member(param)
    members = param[:message][:text].split
    members.shift
    if members.length < 1
      send_msg_obj = Message.create_text_obj("Usage: 抽選 [Usernames ..]\nex. 抽選 ユーザ1 ユーザ2 ユーザ3")
      LineApi.reply(param[:replyToken], send_msg_obj)
      return 
    end
    select_num = members.first.to_i == 0 ? 1 : members.shift.to_i
    select_num = 1 if select_num < 1
    selected_members = Member.random(select_num, members)
    response_message = "抽選結果はこちら！\n#{selected_members.sort.join(',')}"
    send_msg_obj = Message.create_text_obj(response_message)
    LineApi.reply(param[:replyToken], send_msg_obj)
  end

  def competition(param, level)
    xml = HTTParty.get("http://www.sportsone.jp/xml/events_stock.xml", :format => :xml)
    response_message = ["#{level}の試合リストです"]
    xml['rss']['channel']['item'].map do |item|
      desc = item['description'].split(/[|;]/)
      if item['title'].include?('バスケット') && item['title'].include?("【#{level}】") && 
        (desc[2].include?('東京') || desc[2].include?('千葉')) && !desc[9].include?('満員')
        response_message.push("------------------")
        response_message.push("#{desc[1].split(':')[0]} #{desc[15]}～")
        response_message.push("#{desc[3].split(':')[0]} #{desc[9]}")
        response_message.push("#{item['link']}")
      end
      break if response_message.size >= 37
    end
    response_message.push("------------------")
    response_message.push("and more.. http://www.sportsone.jp/basketball/")
    response_message.push("レベルについて： http://www.sportsone.jp/basketball/beginner.html#level")
    send_msg_obj = Message.create_text_obj(response_message.join("\n"))
    LineApi.reply(param[:replyToken], send_msg_obj)
  end

  def competition2(param, level)
    class_id = case level
      when 'よち'    then 20
      when 'ぷち'    then 39
      when 'ぴよ'    then 9
      when 'わい'    then 10
      when 'よちMIX' then 21
      when 'ぷちMIX' then 40
      when 'ぴよMIX' then 16
    end
    date = nil
    time = nil
    location = nil
    vacancy = nil
    link = nil
    html = HTTParty.get("https://cry55.com/products/list.php?mode=search&area_id[]=12&area_id[]=36&class_id[]=#{class_id}&search=")
    response_message = ["#{level}の試合リストです"]
    lines = html.split("\n")
    lines.each_with_index do |line, index|
      date = lines[index+1].strip if line.include?("tournament-list-article__item schedule")
      time = Sanitize.clean(line).strip  if line.include?("tournament-list-article__item meeting")
      location = Sanitize.clean(line).strip if line.include?("tournament-list-article__item state")
      vacancy = lines[index+2].strip if line.include?("<!--FS ADD-->")
      link = line.split("\"")[1] if line.include?("詳細・申し込み")
      if line.include?("tournament-list-article__title") && !date.nil? && !time.nil? && !location.nil? && !vacancy.blank? && !link.nil?
        response_message.push("------------------")
        response_message.push("#{date} #{time}")
        response_message.push("#{Sanitize.clean(line).strip}【#{location}】 残り#{vacancy}")
        response_message.push("https://cry55.com#{link}")
        date = nil
        time = nil
        location = nil
        vacancy = nil
        link = nil
      end
      break if response_message.size >= 37
    end
    response_message.push("------------------")
    response_message.push("and more.. https://cry55.com/products/list.php?mode=search&area_id[]=12&area_id[]=36&class_id[]=#{class_id}&search=")
    response_message.push("レベルについて： https://cry55.com/user_data/class.php")
    send_msg_obj = Message.create_text_obj(response_message.join("\n"))
    LineApi.reply(param[:replyToken], send_msg_obj)
  end

  def calc(param)
    answer = Calculator.calc(param[:message][:text])
    send_msg_obj = Message.create_text_obj(answer)
    LineApi.reply(param[:replyToken], send_msg_obj)
  end

  def participation(param)
    unless param[:source][:userId]
      send_msg_obj = Message.create_text_obj("参加可否登録用URLの取得は私との個人ラインでのみ有効です。")
      LineApi.reply(param[:replyToken], send_msg_obj)
      return
    end
    user = User.find_by(line_user_id: param[:source][:userId])
    raise 'DBがfollow状況と不整合です' unless user
    send_msg_obj = Message.create_text_obj("参加可否の登録はこちらのURLからどうぞ！(#{user.name}さん専用のURLです。PCからもアクセスできます。)\n#{Settings.base_url}schedule/#{user.random}")
    LineApi.reply(param[:replyToken], send_msg_obj)
  end

  def generate_random_hash(param)
    unless param[:source][:userId]
      send_msg_obj = Message.create_text_obj("参加可否登録用URLの変更は私との個人ラインでのみ有効です。")
      LineApi.reply(param[:replyToken], send_msg_obj)
      return
    end
    user = User.find_by(line_user_id: param[:source][:userId])
    raise 'DBがfollow状況と不整合です' unless user
    user.random = User.generate_random(50)
    user.save!
    send_msg_obj = Message.create_text_obj("参加可否登録用URLを変更しました！以下のURLからアクセスしてください。(以前のURLは利用出来なくなりました。)\n#{Settings.base_url}schedule/#{user.random}")
    LineApi.reply(param[:replyToken], send_msg_obj)
  end

  def setting(param)
    unless param[:source][:userId]
      send_msg_obj = Message.create_text_obj("通知設定の確認は私との個人ラインでのみ有効です。")
      LineApi.reply(param[:replyToken], send_msg_obj)
      return
    end
    user = User.find_by(line_user_id: param[:source][:userId])
    raise 'DBがfollow状況と不整合です' unless user
    response_message = [
      "#{user.name}さんの現在の通知設定は以下の通りです。",
      "【リマインド設定】#{user.remind_display_value}",
      "【リクエスト設定】#{user.request_display_value}",
      "------------------",
      "※リマインド設定：参加予定日の前日に私から個人ラインでリマインダーを送信します。",
      "※リクエスト設定：1週間以内に開催予定のイベントの参加可否が未入力の場合、入力を依頼するメッセージを私から送信します。",
      "〇設定変更方法〇",
      "リマインド設定を有効にする場合は個人ラインで「リマインドオン」と発言してください。無効にする場合は「リマインドオフ」",
      "リクエスト設定を有効にする場合は個人ラインで「リクエストオン」と発言してください。無効にする場合は「リクエストオフ」",
    ].join("\n")
    send_msg_obj = Message.create_text_obj(response_message)
    LineApi.reply(param[:replyToken], send_msg_obj)
  end

  def set_remind(param, value)
    unless param[:source][:userId]
      send_msg_obj = Message.create_text_obj("通知設定の変更は私との個人ラインでのみ有効です。")
      LineApi.reply(param[:replyToken], send_msg_obj)
      return
    end
    user = User.find_by(line_user_id: param[:source][:userId])
    raise 'DBがfollow状況と不整合です' unless user
    user.remind = value
    user.save!
    user.reload
    send_msg_obj = Message.create_text_obj("リマインド設定を#{user.remind_display_value}にしました。")
    LineApi.reply(param[:replyToken], send_msg_obj)
  end

  def set_request(param, value)
    unless param[:source][:userId]
      send_msg_obj = Message.create_text_obj("通知設定の変更は私との個人ラインでのみ有効です。")
      LineApi.reply(param[:replyToken], send_msg_obj)
      return
    end
    user = User.find_by(line_user_id: param[:source][:userId])
    raise 'DBがfollow状況と不整合です' unless user
    user.request = value
    user.save!
    send_msg_obj = Message.create_text_obj("リクエスト設定を#{user.request_display_value}にしました。")
    LineApi.reply(param[:replyToken], send_msg_obj)
  end

  def schedule(param)
    send_msg_obj = Message.create_text_obj("参加表の確認はこちらからどうぞ！\n#{Settings.base_url}schedule")
    LineApi.reply(param[:replyToken], send_msg_obj)
  end

  def movie(param)
    send_msg_obj = Message.create_text_obj("練習や試合の動画は以下のURLからどうぞ！\nhttps://www.dropbox.com/sh/ueb7pq48a4v0u9o/AADqB9mhYdgc_jzk8nwX_WWla?dl=0")
    LineApi.reply(param[:replyToken], send_msg_obj)
  end

  def update(param)
    unless param[:source][:userId]
      send_msg_obj = Message.create_text_obj("ユーザ情報の更新は私との個人ラインでのみ有効です。")
      LineApi.reply(param[:replyToken], send_msg_obj)
      return
    end
    profile = LineApi.profile(param[:source][:userId]);
    user = User.find_by(line_user_id: profile[:userId])
    raise 'DBがfollow状況と不整合です' unless user
    user.name = profile[:displayName]
    user.profile_image_url = profile[:pictureUrl]
    user.save!
    send_msg_obj = Message.create_text_obj("ユーザ情報を更新しました！")
    LineApi.reply(param[:replyToken], send_msg_obj)
  end

  def add_reservation(param)
    send_msg_obj = nil
    responses = GoogleCalendar.new.add_reservation(param[:message][:text])
    unless responses.empty?
      response_message = ["予定をカレンダーに登録しました。"]
      responses.each do |response|
        response_message.push('-------------------')
        response_message.push("#{response.html_link}")
      end
      send_msg_obj = Message.create_text_obj(response_message.join("\n"))
    else
      send_msg_obj = Message.create_text_obj("パース処理に失敗しました。フォーマットが正しい場合、管理者に問い合わせてください。")
    end
    LineApi.reply(param[:replyToken], send_msg_obj)
  end

  def summary(param)
    schedules = Schedule.in_future.not_cancelled.not_personal_practice.order_by_start
    response_message = ['参加表のサマリです～']
    response_message.push('-------------------')
    is_recent = true
    require_notice = false
    schedules.each do |schedule|
      response_message.push("・#{schedule.date_ja(true).split("\n")[0]} #{schedule.description}") 
      response_message.push("    〇#{schedule.count_ok} △#{schedule.count_un} ×#{schedule.count_ko}")
      require_notice = true if schedule.start < (Time.now + 5.day).beginning_of_day && schedule.count_ok <= 3 && !schedule.description.include?('（浦）')
    end
    response_message.push("-------------------\n直近5日以内の予約で参加人数が3人以下の日があります。キャンセル忘れに注意してください。") if require_notice
    send_msg_obj = Message.create_text_obj(response_message.join("\n"))
    LineApi.reply(param[:replyToken], send_msg_obj)
  end

  def start_dialogue(param, msg, source_id)
    `touch #{ROOT_DIR}/tmp/#{source_id}`
    send_msg_obj = Message.create_text_obj("#{msg}！少しお話しましょうか！")
    LineApi.reply(param[:replyToken], send_msg_obj)
  end

  def finish_dialogue(param, msg, source_id)
    `rm #{ROOT_DIR}/tmp/#{source_id}`
    send_msg_obj = Message.create_text_obj("#{msg}！楽しかったです、またお話しましょう！")
    LineApi.reply(param[:replyToken], send_msg_obj)
  end

  def dialogue(param, msg, source_id)
    context = `cat #{ROOT_DIR}/tmp/#{source_id}`
    response_json = `curl -H "Accept: application/json" -H "Content-type: application/json" -X POST -d '{"utt":#{msg.inspect}, "context":"#{context.strip}"}' "https://api.apigw.smt.docomo.ne.jp/dialogue/v1/dialogue?APIKEY=#{Settings.docomo.dialogue.api_key}"`
    response = JSON.parse(response_json, symbolize_names: true)
    `echo #{response[:context]} > #{ROOT_DIR}/tmp/#{source_id}`
    send_msg_obj = Message.create_text_obj("#{response[:utt]}")
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
    if user
      Participation.where(user_id: user.id).delete_all
      user.destroy!
    end
  end

  def help(param)
    response_message = [
      "【反応する発言】説明",
      "------------------",
      "【*画像*】\nスラムダンクの名場面っぽい画像を送ります。",
      "【*名言*】\nスラムダンクの名言っぽいセリフをつぶやきます。",
      "【参加表】\n参加表のURLを返します。",
      "【サマリ】\n参加表のサマリを返します。",
      "【動画URL】\n練習や試合動画の参照用URLを返します。",
      "【(四則演算の数式)】\n計算結果を返します。",
      "【超初級|初級|初中級|中級】\n東京と千葉のSportsOne主催の試合リストを表示します。",
      "【よち|ぷち|ぴよ|わい|よちMIX|ぷちMIX|ぴよMIX】\n東京と千葉のCRYSTAREA主催の試合リストを表示します。",
      "【チーム分け】\n続けてユーザ名を空白区切りで入力すると、ランダムにチーム分けします。",
      "【抽選】\n続けてユーザ名を空白区切りで入力すると、ランダムにユーザを抽選します。",
      "【qr:*】\n任意の文字列(*)を表すQRコードを生成します。",
      "【ゲーム】\nスマホで遊べるゲームの一覧を返します。",
      "【おはよう|こんにちは|こんばんは】\nヘッドコーチと雑談を始めます。",
      "【さようなら】\nヘッドコーチとの雑談を終了します。",
      "【参加可否】\n参加表の登録用URLを取得します。(個人LINEでのみ有効)",
      "【URL変更】\n参加表の登録用URLを変更します。(個人LINEでのみ有効)",
      "【ユーザ情報更新】\nLINEのユーザ名や画像の変更を、参加表の表示に反映します。(個人LINEでのみ有効)"
    ].join("\n")
    send_msg_obj = Message.create_text_obj(response_message)
    LineApi.reply(param[:replyToken], send_msg_obj)
  end
end
