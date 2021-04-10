module SanctuaryBot
  class Error < ::StandardError
  end

  class << self
    def config
      @config ||= Config.new
    end

    def bible_api_client
      @bible_api_client ||= BibleApi::Client.new
    end

    def discord_api_client
      @discord_api_client ||= SanctuaryBot::DiscordApi::Client.new
    end

    def logger
      @logger ||= begin
        logger = Logger.new($stderr)
        logger.level = Logger::UNKNOWN
        logger
      end
    end

    def logger=(log)
      @logger = log
    end

    def sanctuary_env
      @sanctuary_env ||= ENV["SANCTUARY_ENV"] || "prod"
    end

    def sanctuary_env=(val)
      @sanctuary_env = val
    end
  end
end

require "sanctuary_bot/config"
require "sanctuary_bot/bible_api"
require "sanctuary_bot/discord_api"
require "sanctuary_bot/webhook"
