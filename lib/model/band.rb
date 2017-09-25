class Band
  # 日本のタイムゾーンのオフセット(9h: 9/24=0.375)
  TIME_ZONE_OFFSET = 0.375

  def list
    events = []
    event = {}
    html = HTTParty.get("#{Settings.url.band}")
    html.each_line do |line|
      key, val = line.chomp.split(':')
      event = {} if key == 'BEGIN' && val == 'VEVENT'
      event[:start] = DateTime.parse(val).new_offset(TIME_ZONE_OFFSET) if key == 'DTSTART'
      event[:end] = DateTime.parse(val).new_offset(TIME_ZONE_OFFSET) if key == 'DTEND'
      event[:summary] = "(浦)#{val}" if key == 'SUMMARY'
      event[:is_cancelled] = val.include?('キャンセル') if key == 'SUMMARY'
      events.push(event) if key == 'END' && val == 'VEVENT' && validate(event)
    end
    events
  end

  private

  # 取り込むイベントのフィルタリング
  def validate(event)
    return false unless event[:start] && event[:end] && event[:summary] && event.has_key?(:is_cancelled)
    return false if event[:start] < DateTime.now.new_offset(TIME_ZONE_OFFSET)
    return false if event[:summary].include?('MGM') || event[:summary].include?('お誕生日')
    return false unless event[:summary].include?('館')
    true
  end
end
