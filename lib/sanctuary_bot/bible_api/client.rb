require "faraday"
require "json"

module SanctuaryBot
  module BibleApi
    class Client
      def initialize(api_key: nil, logger: nil)
        @api_key = api_key || SanctuaryBot.config.bible_api_key
        @logger = logger || SanctuaryBot.logger
        @faraday = Faraday.new(
          url: "https://api.scripture.api.bible",
          headers: {
            "api-key" => api_key
          }
        )
      end

      def translations(language: nil)
        params = {"language" => language} if language
        data = call_api(path: "/v1/bibles", params: params)
        Translation.parse_multi(data)
      end

      def translation(id:)
        data = call_api(path: "/v1/bibles/#{id}")
        Translation.parse(data)
      end

      def passage(reference:, translation: nil)
        translation ||= Translation.default
        pass_id = Passage.to_id(reference)
        params = {
          "content-type" => "text",
          "include-titles" => "false"
        }
        data = call_api(path: "/v1/bibles/#{translation.id}/passages/#{pass_id}", params: params)
        Passage.new(translation: translation, data: data)
      end

      private

      def call_api(path:, params: nil)
        @logger.info("Calling Bible API: #{path}")
        response = @faraday.get(path) do |req|
          req.params = params if params
        end
        status = response.status
        body = begin
          JSON.parse(response.body)
        rescue JSON::ParserError
          status = 500
          {"message" => "Bad result format"}
        end
        unless status == 200 && body["data"]
          message = body["message"] || "Unknown error"
          error = "the Bible API returned an error: #{message}"
          @logger.info(error)
          raise Error, error
        end
        @logger.info("Got data from Bible API")
        body["data"]
      end
    end
  end
end
