require "faraday"
require "json"
require "uri"

module SanctuaryBot
  module DiscordApi
    class Client
      def initialize(client_id: nil, client_secret: nil, guild_id: nil, logger: nil)
        @logger = logger || SanctuaryBot.logger
        @client_id = client_id || SanctuaryBot.config.discord_client_id
        @client_secret = client_secret || SanctuaryBot.config.discord_client_secret
        @guild_id = guild_id || SanctuaryBot.config.discord_guild_id
        @refresh_time = 0
        @access_token = ""
      end

      def list_user_guilds
        call_api(path: "/users/@me/guilds")
      end

      def list_guild_commands
        call_api(path: "/applications/#{@client_id}/guilds/#{@guild_id}/commands")
      end

      def create_guild_command(data)
        call_api(path: "/applications/#{@client_id}/guilds/#{@guild_id}/commands",
                 method: :post, body: JSON.dump(data),
                 headers: {"Content-Type" => "application/json"})
      end

      def delete_guild_command(id)
        call_api(path: "/applications/#{@client_id}/guilds/#{@guild_id}/commands/#{id}",
                 method: :delete)
      end

      def create_followup_message(token, data)
        call_api(path: "/webhooks/#{@client_id}/#{token}", params: {wait: "true"},
                 method: :post, body: JSON.dump(data),
                 headers: {"Content-Type" => "application/json"})
      end

      def edit_interaction_response(token, data)
        call_api(path: "/webhooks/#{@client_id}/#{token}/messages/@original",
                 method: :patch, body: JSON.dump(data),
                 headers: {"Content-Type" => "application/json"})
      end

      def token_info
        call_api(path: "/oauth2/@me")
      end

      def revoke_token
        maybe_refresh_token
        request_data = {"token" => @access_token}
        conn = Faraday.new
        conn.basic_auth(@client_id, @client_secret)
        conn.post("https://discord.com/api/oauth2/token/revoke", URI.encode_www_form(request_data))
      end

      private

      def call_api(path:, method: :get, body: nil, params: nil, headers: nil, allow_retry: true)
        @logger.info("Calling discord API")
        maybe_refresh_token
        faraday = Faraday.new(url: "https://discord.com") do |conn|
          conn.authorization(:Bearer, @access_token)
        end
        response = faraday.run_request(method, "/api/v8#{path}", body, headers) do |req|
          req.params = params if params
        end
        if response.status == 429
          response_body = JSON.parse(response.body) rescue nil
          delay = response_body["retry_after"] if response_body
          if delay && delay < 5
            @logger.info("Got rate limited. Retrying after #{delay}")
            sleep(delay + 0.1)
            return call_api(path: path, method: method, body: body,
                            params: params, headers: headers, allow_retry: false)
          end
        end
        if response.status < 200 || response.status >= 300
          raise Error, "Failure status from Discord API: #{response.status} #{response.body.inspect}"
        end
        return nil if response.body.nil? || response.body.empty?
        begin
          JSON.parse(response.body)
        rescue JSON::ParserError => e
          raise Error, "Bad response from Discord API: #{e.inspect}"
        end
      end

      def maybe_refresh_token
        return false if Time.now.to_i < @refresh_time
        data = retrieve_token_data
        raise Error, "Unable to retrieve access token" if data.nil?
        @access_token = data["access_token"]
        @refresh_time = Time.now.to_i + data["expires_in"] - 600
      end

      def retrieve_token_data
        @logger.info("Refreshing access token")
        request_data = {
          "grant_type" => "client_credentials",
          "scope" => "applications.commands.update"
        }
        conn = Faraday.new
        conn.basic_auth(@client_id, @client_secret)
        response = conn.post("https://discord.com/api/v8/oauth2/token", URI.encode_www_form(request_data))
        return nil unless response.status == 200
        begin
          JSON.parse(response.body)
        rescue JSON::ParserError
          nil
        end
      end
    end
  end
end
