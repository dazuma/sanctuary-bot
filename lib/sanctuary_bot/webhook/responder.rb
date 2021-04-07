module SanctuaryBot
  module Webhook
    class Responder
      def initialize(logger: nil, verification_key: nil)
        @logger = logger || SanctuaryBot.logger
        verification_key ||= SanctuaryBot.config.discord_public_key
        verification_key = Ed25519::VerifyKey.new([verification_key].pack("H*")) if verification_key.is_a?(String)
        @verification_key = verification_key
        @handlers = []
      end

      def add_handler(handler)
        handler = handler.new(logger: @logger) if handler.is_a?(Class)
        @handlers << handler
        self
      end

      def respond(rack_request)
        interaction = Interaction.from_request(rack_request, verification_key: @verification_key)
        return invalid_signature_response(interaction) if interaction.verification_error
        return bad_request_response(interaction) if interaction.format_error
        case interaction.type
        when 1
          pong_response(interaction)
        when 2
          command_response(interaction)
        else
          unknown_type_response(interaction)
        end
      end

      protected

      def invalid_signature_response(interaction)
        @logger.error(interaction.verification_error)
        @logger.error("Reporting invalid signature received")
        [401, {"Content-Type" => "text/plain"}, ["invalid request signature"]]
      end

      def bad_request_response(interaction)
        @logger.error(interaction.format_error)
        @logger.error("Reporting bad request format received")
        [400, {"Content-Type" => "text/plain"}, ["bad request format"]]
      end

      def pong_response(_interaction)
        @logger.info("Responding to ping with pong")
        ResponseBuilder.pong.to_json_object
      end

      def unknown_type_response(interaction)
        @logger.error("Reporting bad interaction type code received: #{interaction.type}")
        [400, {"Content-Type" => "text/plain"}, ["bad interaction type"]]
      end

      def command_response(interaction)
        @handlers.each do |handler|
          if handler.should_handle?(interaction)
            response_json = JSON.dump(handler.handle(interaction))
            @logger.info(response_json)
            return [200, {"Content-Type" => "application/json; charset=utf-8"}, [response_json]]
          end
        end
        @logger.error("Command not handled: #{interaction.command_data&.name.inspect}")
        [500, {"Content-Type" => "text/plain"}, ["Command not handled."]]
      end
    end
  end
end
