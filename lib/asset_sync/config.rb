module AssetSync
  class Config
    include ActiveModel::Validations

    class Invalid < StandardError; end

    # AssetSync
    attr_accessor :manifest
    attr_accessor :fail_silently
    attr_accessor :log_silently
    attr_accessor :always_upload
    attr_accessor :ignored_files
    attr_accessor :prefix
    attr_accessor :public_path
    attr_accessor :enabled
    attr_accessor :custom_headers
    attr_accessor :run_on_precompile
    attr_accessor :invalidate

    attr_accessor :mongo


    def initialize
      self.manifest = false
      self.fail_silently = false
      self.log_silently = true
      self.always_upload = []
      self.ignored_files = []
      self.custom_headers = {}
      self.enabled = true
      self.run_on_precompile = true
      self.invalidate = []
      load_yml! if defined?(Rails) && yml_exists?
    end

    def manifest_path
      directory =
        Rails.application.config.assets.manifest || default_manifest_directory
      File.join(directory, "manifest.yml")
    end

    def fail_silently?
      fail_silently || !enabled?
    end

    def log_silently?
      !!self.log_silently
    end

    def enabled?
      enabled == true
    end

    def yml_exists?
      defined?(Rails.root) ? File.exist?(self.yml_path) : false
    end

    def yml
      begin
        @yml ||= YAML.load(ERB.new(IO.read(yml_path)).result)[Rails.env] rescue nil || {}
      rescue Psych::SyntaxError
        @yml = {}
      end
    end

    def yml_path
      Rails.root.join("config", "asset_sync.yml").to_s
    end

    def assets_prefix
      # Fix for Issue #38 when Rails.config.assets.prefix starts with a slash
      self.prefix || Rails.application.config.assets.prefix.sub(/^\//, '')
    end

    def public_path
      @public_path || Rails.public_path
    end

    def load_yml!
      self.enabled                = yml["enabled"] if yml.has_key?('enabled')
      self.manifest               = yml["manifest"] if yml.has_key?("manifest")
      self.fail_silently          = yml["fail_silently"] if yml.has_key?("fail_silently")
      self.always_upload          = yml["always_upload"] if yml.has_key?("always_upload")
      self.ignored_files          = yml["ignored_files"] if yml.has_key?("ignored_files")
      self.custom_headers          = yml["custom_headers"] if yml.has_key?("custom_headers")
      self.run_on_precompile      = yml["run_on_precompile"] if yml.has_key?("run_on_precompile")
      self.invalidate             = yml["invalidate"] if yml.has_key?("invalidate")
      self.public_path            = yml["public_path"] if yml.has_key?("public_path")
    end
    private

    def default_manifest_directory
      File.join(Rails.public_path, assets_prefix)
    end
  end
end
