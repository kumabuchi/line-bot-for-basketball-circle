class LineApi
  @@endpoint_uri = 'https://api.line.me/v2/bot/'
  @@default_header = {
    'Content-Type'  => 'application/json',
    'Authorization' => "Bearer #{Settings.line.access_token}"
  }

  def self.reply(token, send_msg_obj)
    contents = { replyToken: token, messages: [send_msg_obj].flatten }
    RestClient.post(@@endpoint_uri+'message/reply', contents.to_json, @@default_header)
  end

  def self.push(to, send_msg_obj)
    contents = { to: to, messages: [send_msg_obj].flatten }
    RestClient.post(@@endpoint_uri+'message/push', contents.to_json, @@default_header)
  end

  def self.profile(user_id)
    response = RestClient.get("#{@@endpoint_uri}profile/#{user_id}", @@default_header)
    JSON.parse(response.body, symbolize_names: true)
  end
end
