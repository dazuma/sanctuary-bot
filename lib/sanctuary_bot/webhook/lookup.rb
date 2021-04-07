module SanctuaryBot
  module Webhook
    class Lookup
      def self.command_spec(name)
        {
          "name" => name,
          "description" => "Simple scripture lookup",
          "options" => [
            {
              "type" => 3,
              "name" => "reference",
              "description" => "Scripture reference",
              "required" => true
            }
          ]
        }
      end

      def initialize(logger: nil, bible_api_client: nil)
        @logger = logger || SanctuaryBot.logger
        @bible_api_client = bible_api_client || SanctuaryBot.bible_api_client
      end

      attr_reader :bible_api_client

      def should_handle?(interaction)
        interaction.command_data&.name == SanctuaryBot.config.lookup_command
      end

      def handle(interaction)
        reference = interaction.command_data.option("reference").strip
        @logger.info("Looking up reference: #{reference.inspect}")
        response_str = begin
          passage = bible_api_client.passage(reference: reference)
          if passage.full_content.length < 2000
            passage.full_content
          else
            too_long_string(passage.full_content, passage.reference)
          end
        rescue SanctuaryBot::Error => e
          error_string(e.message, reference)
        end
        ResponseBuilder.message.content(response_str).to_json_object
      end

      def error_string(str, reference)
        "🤖 - Sorry, I couldn't display '#{reference}' because #{str}"
      end

      def too_long_string(content, reference)
        str = "the passage is longer than I can show in a message." \
          " (I can show up to 2000 characters, but the passage is #{content.length} characters.)" \
          " Try requesting a shorter passage, or break it up into sections."
        error_string(str, reference)
      end
    end
  end
end
