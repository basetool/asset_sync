module AssetSync
  class Storage
    REGEXP_FINGERPRINTED_FILES = /^(.*)\/([^-]+)-[^\.]+\.([^\.]+)$/

    class BucketNotFound < StandardError;
    end

    attr_accessor :config

    def initialize(cfg)
      @config = cfg
    end

    def connection
    end

    def bucket
    end

    def log(msg)
      AssetSync.log(msg)
    end

    def path
      self.config.public_path
    end

    def ignored_files
      files = []
      Array(self.config.ignored_files).each do |ignore|
        case ignore
          when Regexp
            files += self.local_files.select do |file|
              file =~ ignore
            end
          when String
            files += self.local_files.select do |file|
              file.split('/').last == ignore
            end
          else
            log "Error: please define ignored_files as string or regular expression. #{ignore} (#{ignore.class}) ignored."
        end
      end
      files.uniq
    end

    def local_files
      @local_files ||= get_local_files.uniq
    end

    def always_upload_files
      self.config.always_upload.map { |f| File.join(self.config.assets_prefix, f) }
    end

    def files_with_custom_headers
      self.config.custom_headers.inject({}) { |h,(k, v)| h[File.join(self.config.assets_prefix, k)] = v; h; }
    end

    def files_to_invalidate
      self.config.invalidate.map { |filename| File.join("/", self.config.assets_prefix, filename) }
    end

    def get_local_files
      if self.config.manifest
        if ActionView::Base.respond_to?(:assets_manifest)
          log "Using: Rails 4.0 manifest access"
          manifest = Sprockets::Manifest.new(ActionView::Base.assets_manifest.environment, ActionView::Base.assets_manifest.dir)
          return manifest.assets.values.map { |f| File.join(self.config.assets_prefix, f) }
        elsif File.exist?(self.config.manifest_path)
          log "Using: Manifest #{self.config.manifest_path}"
          yml = YAML.load(IO.read(self.config.manifest_path))
   
          return yml.map do |original, compiled|
            # Upload font originals and compiled
            if original =~ /^.+(eot|svg|ttf|woff)$/
              [original, compiled]
            else
              compiled
            end
          end.flatten.map { |f| File.join(self.config.assets_prefix, f) }.uniq!
        else
          log "Warning: Manifest could not be found"
        end
      end
      log "Using: Directory Search of #{path}/#{self.config.assets_prefix}"
      Dir.chdir(path) do
        to_load = self.config.assets_prefix.present? ? "#{self.config.assets_prefix}/**/**" : '**/**'
        Dir[to_load]
      end
    end


    def upload_file(f)
      AssetSync::Mongo.upload(config,f)
    end

    def upload_files
      local_files_to_upload = local_files - ignored_files  + always_upload_files
      local_files_to_upload = (local_files_to_upload + get_non_fingerprinted(local_files_to_upload)).uniq

      # Upload new files
      local_files_to_upload.each do |f|
        next unless File.file? "#{path}/#{f}" # Only files.
        upload_file f
      end
    end

    def sync
      # fixes: https://github.com/rumblelabs/asset_sync/issues/19
      log "AssetSync: Syncing."
      upload_files
      log "AssetSync: Done."
    end

    private

    def get_non_fingerprinted(files)
      files.map do |file|
        match_data = file.match(REGEXP_FINGERPRINTED_FILES)
        match_data && "#{match_data[1]}/#{match_data[2]}.#{match_data[3]}"
      end.compact
    end

  end
end
