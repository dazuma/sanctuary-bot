require "psych"

module SanctuaryBot
  class Config
    OPEN_FILE_PATH = File.expand_path("../../config-open.yaml", __dir__)
    SECURE_FILE_PATH = File.expand_path("../../config-secure.yaml", __dir__)
    SERVICE_ACCOUNT_PATH = File.expand_path("../../service-account.json", __dir__)

    OPEN_KEYS = [
      :gcp_project_id,
      :gcp_project_number,
      :gcp_function_name,
      :secret_name,
      :discord_guild_id,
      :lookup_command,
      :help_command
    ]
    SECURE_KEYS = [
      :bible_api_key,
      :discord_client_id,
      :discord_client_secret,
      :discord_public_key
    ]

    def initialize(logger: nil)
      @logger = logger || SanctuaryBot.logger
      @open_loaded = @secure_loaded = false
      @values = {}
    end

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

    def upload_secure_file
      raise "Secure file not found" unless File.file?(SECURE_FILE_PATH)
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
        payload: {data: File.read(SECURE_FILE_PATH)}
      )
      @logger.info("Uploaded secrets to secret manager")
    end

    def secure_file_exists?
      File.file?(SECURE_FILE_PATH)
    end

    def write_secure_file
      load_secure
      secure_data = {}
      SECURE_KEYS.each { |key| secure_data[key.to_s] = @values[key] }
      @logger.info("Writing secure file")
      File.open(SECURE_FILE_PATH, "w") do |file|
        file.write(Psych.dump(secure_data))
      end
      @logger.info("Secure file written")
    end

    private

    def secret_manager
      @secret_manager ||= begin
        if File.file?(SERVICE_ACCOUNT_PATH)
          ENV["GOOGLE_APPLICATION_CREDENTIALS"] = SERVICE_ACCOUNT_PATH
        end
        require "google/cloud/secret_manager"
        Google::Cloud::SecretManager.secret_manager_service
      end
    end

    def load_open
      return if @open_loaded
      @logger.info("Loading open parameters from file")
      data = Psych.load_file(OPEN_FILE_PATH)
      load_from_yaml(data, OPEN_KEYS, "open config file")
      @open_loaded = true
    end

    def load_secure
      return if @secure_loaded
      if File.file?(SECURE_FILE_PATH)
        @logger.info("Loading secure parameters from file")
        data = Psych.load_file(SECURE_FILE_PATH)
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
