Dir["#{File.dirname(__FILE__)}/controller/**/*.rb"].sort.each do |controller|
  require(controller)
end

class Controller < Sinatra::Base
  # TODO: schedule/webhookをmoduleで実装し、ここで読み込む
  get '/' do
    'Hello World!'
  end
end
