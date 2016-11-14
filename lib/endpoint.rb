Dir["#{File.dirname(__FILE__)}/endpoint/**/*.rb"].sort.each do |endpoint|
  require(endpoint)
end
