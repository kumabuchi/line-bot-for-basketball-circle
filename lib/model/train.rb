class Train

  def get_all
    @traininfo = {}
    html = HTTParty.get("#{Settings.url.transit}")
    lines = html.split("\n")
    lines.each_with_index do |line, index|
      if line.include?("https://transit.yahoo.co.jp/traininfo/detail/")
        routename = Sanitize.clean(line).strip
        message = "#{Sanitize.clean(lines[index+1]).strip}: #{Sanitize.clean(lines[index+2]).strip}"
        url = line.split("\"")[1]
        @traininfo[routename] = {routename: routename, message: message, url: url}
      end
    end 
    @traininfo.symbolize_keys
  end

  def get_trouble_only
    @traininfo = get_all if @traininfo.nil?
    @traininfo.select { |route, info| !info[:message].include?("平常運転") }
  end

  def get_by_routename(routename)
    @traininfo = get_all if @traininfo.nil?
    @traininfo.select { |route, info| info[:routename].include?(routename) }
  end

  def get_train_info(routenames)
    return get_trouble_only if routenames.nil? || routenames.length < 1
    #return get_all if routenames.include?('全路線') # bug: 全路線は多すぎて400 Bad Requestになる
    train_info = {}
    routenames.each do |routename|
      train_info.merge!(get_by_routename(routename))
    end
    train_info
  end
end
