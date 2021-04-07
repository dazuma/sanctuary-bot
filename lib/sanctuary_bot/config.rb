require "psych"

module SanctuaryBot
  class Config
    OPEN_KEYS = [
      :discord_client_id,
      :discord_guild_id,
      :discord_public_key,
      :gcp_function_name,
      :gcp_project_id,
      :gcp_project_number,
      :help_command,
      :lookup_command,
      :secret_name,
    ]
    SECURE_KEYS = [
      :bible_api_key,
      :discord_client_secret,
    ]

    OPEN_KEYS.each do |key|
      define_method(key) do
        load_open
        @values[key]
      end
    end

    SECURE_KEYS.each do |key|
      define_method(key) do
        load_secure
        @values[key]
      end
    end

    def initialize(logger: nil, sanctuary_env: nil)
      sanctuary_env ||= SanctuaryBot.sanctuary_env
      @logger = logger || SanctuaryBot.logger
      @open_loaded = @secure_loaded = false
      @values = {}
      @open_file_path = File.expand_path("../../config/open-#{sanctuary_env}.yaml", __dir__)
      @secure_file_path = File.expand_path("../../config/secure-#{sanctuary_env}.yaml", __dir__)
      @service_account_path = File.expand_path("../../config/service-account-#{sanctuary_env}.json", __dir__)
    end

    def upload_secure_file
      raise "Secure file not found" unless File.file?(@secure_file_path)
      secret_path = secret_manager.secret_path(project: gcp_project_id, secret: secret_name)
      begin
        @logger.info("Checking for secret: #{secret_path}")
        secret_manager.get_secret(name: secret_path)
      rescue Google::Cloud::NotFoundError
        @logger.info("Creating secret: #{secret_path}")
        secret_manager.create_secret(
          parent: secret_manager.project_path(project: gcp_project_id),
          secret_id: secret_name,
          secret: {replication: {automatic: {}}}
        )
      end
      @logger.info("Adding secret: #{secret_path}")
      @secrets_version = secret_manager.add_secret_version(
        parent: secret_path,
        payload: {data: File.read(@secure_file_path)}
      )
      @logger.info("Uploaded secrets to secret manager")
    end

    def secure_file_exists?
      File.file?(@secure_file_path)
    end

    def write_secure_file
      load_secure
      secure_data = {}
      SECURE_KEYS.each { |key| secure_data[key.to_s] = @values[key] }
      @logger.info("Writing secure file")
      File.open(@secure_file_path, "w") do |file|
        file.write(Psych.dump(secure_data))
      end
      @logger.info("Secure file written")
    end

    private

    def secret_manager
      @secret_manager ||= begin
        if File.file?(@service_account_path)
          ENV["GOOGLE_APPLICATION_CREDENTIALS"] = @service_account_path
        end
        require "google/cloud/secret_manager"
        Google::Cloud::SecretManager.secret_manager_service
      end
    end

    def load_open
      return if @open_loaded
      @logger.info("Loading open parameters from file")
      data = Psych.load_file(@open_file_path)
      load_from_yaml(data, OPEN_KEYS, "open config file")
      @open_loaded = true
    end

    def load_secure
      return if @secure_loaded
      if File.file?(@secure_file_path)
        @logger.info("Loading secure parameters from file")
        data = Psych.load_file(@secure_file_path)
        load_from_yaml(data, SECURE_KEYS, "secure config file")
      else
        @logger.info("Loading secure parameters from secret manager")
        version_name = secret_manager.secret_version_path(
          project: gcp_project_id, secret: secret_name, secret_version: "latest"
        )
        version = secret_manager.access_secret_version(name: version_name)
        data = Psych.load(version.payload.data)
        @logger.info("Received data from secret manager")
        load_from_yaml(data, SECURE_KEYS, "secret manager data")
      end
      @secure_loaded = true
    end

    def load_from_yaml(data, keys, source)
      raise Error, "Malformed YAML from #{source}" unless data
      keys.each do |key|
        value = data[key.to_s]
        raise "#{key} not found in #{source}" unless value
        @values[key] = value
      end
    end
  end
end
