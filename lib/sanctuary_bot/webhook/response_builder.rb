module SanctuaryBot
  module Webhook
    class ResponseBuilder
      class << self
        def pong
          new.type(1)
        end

        def message
          new.type(4).content("Acknowledged.")
        end

        def deferred_message
          new.type(5).content("thinking...")
        end
      end

      def initialize
        @type = nil
        @content = nil
        @ephemeral = false
        @mention_parse = []
        @mention_roles = []
        @mention_users = []
        @mention_reply = false
      end

      def type(value)
        @type = value
        self
      end

      def content(value)
        @content = value
        self
      end

      def append_content(value)
        @content += value
        self
      end

      def ephemeral(value)
        @ephemeral = value ? true : false
        self
      end

      def mention_parse(*values)
        @mention_parse += values
        self
      end

      def mention_roles(*values)
        @mention_roles += values
        self
      end

      def mention_users(*values)
        @mention_users += values
        self
      end

      def mention_reply(value)
        @mention_reply = value ? true : false
        self
      end

      def to_json_object
        validate!
        response = {"type" => @type}
        if [4, 5].include?(@type)
          data = {"content" => @content.to_s}
          allowed_mentions = {}
          allowed_mentions["parse"] = @mention_parse
          allowed_mentions["roles"] = @mention_roles
          allowed_mentions["users"] = @mention_users
          allowed_mentions["replied_user"] = @mention_reply
          data["allowed_mentions"] = allowed_mentions
          data["flags"] = 64 if @ephemeral
          response["data"] = data
        end
        response
      end

      private

      def validate!
        raise "Illegal type: #{@type.inspect}" unless [1, 4, 5].include?(@type)
        raise "Illegal content: #{@content.inspect}" unless @content.nil? || @content.is_a?(String)
      end
    end
  end
end
