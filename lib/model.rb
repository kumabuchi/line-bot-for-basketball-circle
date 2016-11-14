Dir["#{File.dirname(__FILE__)}/model/**/*.rb"].sort.each do |model|
  require(model)
end
