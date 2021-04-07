require "ed25519"

module SanctuaryBot
  module Webhook
    class CommandData
      def initialize(data)
        @name = data["name"]
        @options = {}
        Array(data["options"]).each do |option|
          @options[option["name"]] = option["value"]
        end
      end

      def option(name)
        @options[name.to_s]
      end

      attr_reader :name
    end
  end
end
