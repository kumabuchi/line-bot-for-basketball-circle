class Calculator
  def self.calc(params)
    params = params.split(':') 
    eq = params[0].chomp.strip
    eq = "0#{eq}" if eq[0] == '+' || eq[0] == '-'
    scale = (params.length > 1 ? params[1] : 1)
    answer = `echo 'scale=#{scale}; #{eq}' | bc 2>&1`.chomp.strip.gsub("\n", "").gsub("\\","")
    answer[0] == '.' ? "0#{answer}" : answer
  end
end
