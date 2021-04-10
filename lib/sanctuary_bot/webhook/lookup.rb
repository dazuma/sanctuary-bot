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
              "description" => "Scripture reference (e.g. `Ps 1` or `Matt 1:18-2:12`)",
              "required" => true
            }
          ]
        }
      end

      def initialize(logger: nil, bible_api_client: nil, pubsub_client: nil)
        @logger = logger || SanctuaryBot.logger
        @bible_api_client = bible_api_client || SanctuaryBot.bible_api_client
        @pubsub_client = pubsub_client || SanctuaryBot.config.pubsub_client
      end

      attr_reader :bible_api_client

      def should_handle?(interaction)
        interaction.command_data&.name == SanctuaryBot.config.lookup_command
      end

      def handle(interaction)
        reference = interaction.command_data.option("reference").strip
        @logger.info("Publishing pubsub message...")
        data = JSON.dump(reference: reference, token: interaction.token)
        config = SanctuaryBot.config
        topic = "projects/#{config.gcp_project_id}/topics/#{config.gcp_pubsub_topic}"
        @pubsub_client.publish(topic: topic, messages: [{data: data}])
        @logger.info("Published.")
        ResponseBuilder.message.content("🤖 - Looking up `#{reference}` ...").to_json_object
      end
    end
  end
end
