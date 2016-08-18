AssetSync.configure do |config|
  config.mongo = Mongo::Client.new([ '192.168.0.238:27017' ], :database => 'whmall')
end
