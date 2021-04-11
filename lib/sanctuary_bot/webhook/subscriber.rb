module SanctuaryBot
  module Webhook
    class Subscriber
      def initialize(logger: nil, bible_api_client: nil, discord_api_client: nil)
        @logger = logger || SanctuaryBot.logger
        @bible_api_client = bible_api_client || SanctuaryBot.bible_api_client
        @discord_api_client = discord_api_client || SanctuaryBot.discord_api_client
      end

      def respond(event)
        data = Base64.decode64(event.data["message"]["data"])
        data.force_encoding(Encoding::UTF_8)
        data = JSON.parse(data)
        reference = data["reference"]
        token = data["token"]

        @logger.info("Looking up reference: #{reference.inspect}")
        begin
          full_passage = @bible_api_client.passage(reference: reference)
          passages = full_passage.split(max_length: 1980 - full_passage.reference.length)
          passages.each_with_index do |passage, index|
            @logger.info("Sending #{passage.reference}")
            data = data_for_passage(passage, full_passage.reference, index + 1, passages.size)
            response = @discord_api_client.create_followup_message(token, data)
            @logger.info(JSON.dump(response))
          end
          finish(token, "Looking up *#{full_passage.full_reference}* ...")
        rescue SanctuaryBot::Error => e
          finish(token, "🤖 - Sorry, I couldn't lookup '#{reference}' because #{e.message}")
        end
      end

      def finish(token, str)
        @logger.info("Setting interaction response: #{str.inspect}")
        data = {
          content: str,
          allowed_mentions: {
            parse: [], roles: [], users: [], replied_user: false
          }
        }
        response = @discord_api_client.edit_interaction_response(token, data)
        @logger.info(JSON.dump(response))
      end

      def data_for_passage(passage, reference, index, size)
        content =
          if size == 1
            "_#{reference}…_\n#{passage.content}"
          else
            "_#{reference} (part #{index} of #{size})…_\n#{passage.content}"
          end
        {
          content: content,
          allowed_mentions: {
            parse: [], roles: [], users: [], replied_user: false
          }
        }
      end
    end
  end
end
