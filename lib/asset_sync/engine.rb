module AssetSync
  class Engine < Rails::Engine

    engine_name "asset_sync"

    initializer "asset_sync config", :group => :all do |app|
      app_initializer = Rails.root.join('config', 'initializers', 'asset_sync.rb').to_s
      app_yaml = Rails.root.join('config', 'asset_sync.yml').to_s

      if File.exist?( app_initializer )
        AssetSync.log "AssetSync: using #{app_initializer}"
        load app_initializer
      elsif !File.exist?( app_initializer ) && !File.exist?( app_yaml )
        AssetSync.log "AssetSync: using default configuration from built-in initializer"
        AssetSync.configure do |config|
          config.enabled = (ENV['ASSET_SYNC_ENABLED'] == 'true') if ENV.has_key?('ASSET_SYNC_ENABLED')
          config.manifest = (ENV['ASSET_SYNC_MANIFEST'] == 'true') if ENV.has_key?('ASSET_SYNC_MANIFEST')
        end
        config.prefix = ENV['ASSET_SYNC_PREFIX'] if ENV.has_key?('ASSET_SYNC_PREFIX')
        config.manifest = (ENV['ASSET_SYNC_MANIFEST'] == 'true') if ENV.has_key?('ASSET_SYNC_MANIFEST')
      end

      if File.exist?( app_yaml )
        AssetSync.log "AssetSync: YAML file found #{app_yaml} settings will be merged into the configuration"
      end
    end

  end
end
