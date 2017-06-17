Bundler.require(:default)
require 'active_record'

ROOT_DIR = File.expand_path("..", __FILE__);
Dir["#{ROOT_DIR}/config/initializers/**/*.rb"].sort.each do |initializer|
  load(initializer)
end

ActiveRecord::Base.establish_connection(
  "adapter"  => Settings.db.adapter,
  "database" => "#{ROOT_DIR}#{Settings.db.path}"
)

require("#{ROOT_DIR}/lib/model.rb")
require("#{ROOT_DIR}/lib/endpoint.rb")
require("#{ROOT_DIR}/lib/controller.rb")

run Controller
