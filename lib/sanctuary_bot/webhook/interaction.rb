require "ed25519"

module SanctuaryBot
  module Webhook
    class Interaction
      def self.from_request(rack_request, verification_key:)
        raw_body = rack_request.body.read
        verification_error =
          if verification_key == :disable_verification
            nil
          else
            timestamp = rack_request.env["HTTP_X_SIGNATURE_TIMESTAMP"].to_s
            signature_hex = rack_request.env["HTTP_X_SIGNATURE_ED25519"].to_s
            signature = [signature_hex].pack("H*")
            begin
              verification_key.verify(signature, timestamp + raw_body)
              nil
            rescue ::StandardError => e
              e
            end
          end
        new(raw_body, verification_error: verification_error)
      end

      def initialize(json, verification_error: nil)
        @verification_error = verification_error
        json = JSON.parse(json) if json.is_a?(::String)
        @interaction_id = json["id"]
        @application_id = json["application_id"]
        @type = json["type"]
        @token = json["token"]
        @command_data = CommandData.new(json["data"]) if json["data"]
        @format_error = nil
      rescue ::StandardError => e
        @format_error = e
      end

      attr_reader :interaction_id
      attr_reader :application_id
      attr_reader :type
      attr_reader :token
      attr_reader :command_data

      attr_reader :verification_error
      attr_reader :format_error
    end
  end
end
