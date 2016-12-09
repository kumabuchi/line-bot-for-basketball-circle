class Calculator
  def self.calc(params)
    params = params.split(':') 
    eq = params[0].chomp.strip
    eq = "0#{eq}" if eq[0] == '+' || eq[0] == '-'
    scale = (params.length > 1 ? params[1] : 1)
    answer_text = `echo 'scale=#{scale}; #{eq}' | bc 2>&1`.chomp.strip.gsub("\n", "").gsub("\\","")
    answer_text = "0#{answer_text}" if answer_text[0] == '.'
    answer = "答えは #{answer_text} ですね！"
    answer = '桁が大きすぎてここに書ききれないようです。。。' if answer_text.length > 1000
    answer = '数式は合っていますか？使える演算子は +-*/%^ です！' if answer_text.include?('error')
    answer = '0で割ってはいけないと学校で習ったはずですが？'  if answer_text.include?('Divide by zero')
    answer
  end
end
