Bundler.require(:default)

require("#{File.dirname(__FILE__)}/lib/model.rb")

Dir["#{File.dirname(__FILE__)}/config/initializers/**/*.rb"].sort.each do |initializer|
  load(initializer)
end

require("#{File.dirname(__FILE__)}/lib/endpoint.rb")
require("#{File.dirname(__FILE__)}/lib/controller.rb")

run Controller
