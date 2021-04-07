module SanctuaryBot
  module Webhook
    class Help
      def self.command_spec(name)
        {
          "name" => name,
          "description" => "Help for Sanctuary-Bot",
          "options" => [
            {
              "type" => 3,
              "name" => "topic",
              "description" => "help topic",
              "required" => false
            }
          ]
        }
      end

      MAIN_HELP_TEXT = <<~TEXT
        Hello! I'm Sanctuary-Bot. I hang out here, and you can tell me to do stuff. Just simple stuff. I'm not all\
         that sophisticated. Or at least not yet. You can give me commands by starting them with a forward-slash\
         character. Here's what I know how to do so far:

            `/word` - This command tells me to look up and display a scripture passage. For example, you can say\
         `/word Matt 1:20-2:5`.

            `/help` - This command displays help for a topic. For example, you can say `/help word` to display help\
         on the `/word` command that looks up scripture passages.

        If I respond with something like "interaction failed", just try again. It might just be that I'm a bit drowsy\
         and need to be awakened. Discord isn't very nice to bots like me, and if I don't respond fast enough, it\
         calls me a "failure." Can you imagine that? But that said, if I start misbehaving _consistently_, then, uhh,\
         yell at the Google guy. What's his name? Oh yeah, "Daniel". The cat. He can fix me if I'm actually broken.
      TEXT

      WORD_HELP_TEXT = <<~TEXT
        The `/word` command looks up and displays a passage from scripture. You can specify the passage by a range of\
         of chapters and verses. You can abbreviate the book name; I'm pretty good at figuring out which one you're\
         talking about. Here are some examples that I can respond to:
            `/word Matt 1:1`
            `/word Ps 23`
            `/word Psalm 1:1-4`
            `/word psa 1:4-2:3`

        A few caveats, though. First, Discord doesn't let me display a really long passage. The limit is about 2000\
         characters. So if the passage is too long, I'll ask you to trim it down. Also, for now I'm limited to the\
         World English Bible, which is in the public domain. (I'm just a bot, not a copyright lawyer.) I may get\
         additional translations later, if Daniel can figure out how. Although he's not copyright lawyer either.
      TEXT

      TOPIC_HELP_TEXT = <<~TEXT
        Sorry, I don't know much about `TOPIC`. Try asking me about `word`.
      TEXT

      ME_HELP_TEXT = <<~TEXT
        Do you need help? Try contacting People Bloom Counseling at https://peoplebloomcounseling.com. It's run by\
         the partner of the cat who wrote me. I'm not biased at all. Really.
      TEXT

      def initialize(logger: nil)
        @logger = logger || SanctuaryBot.logger
        @help_text = [
          [/^(?:word|bible|scripture)$/, WORD_HELP_TEXT],
          ["", MAIN_HELP_TEXT],
          ["me", ME_HELP_TEXT],
          [//, proc { |topic| TOPIC_HELP_TEXT.sub("TOPIC", topic) }]
        ]
      end

      def should_handle?(interaction)
        interaction.command_data&.name == SanctuaryBot.config.help_command
      end

      def handle(interaction)
        topic = interaction.command_data.option("topic").to_s
        canonical_topic = topic.gsub(%r{\W+}, "").downcase
        _pattern, help_text = @help_text.find { |pattern, _help_text| pattern === canonical_topic }
        help_text = help_text.call(topic) if help_text.respond_to?(:call)
        ResponseBuilder.message.content("🤖 - #{help_text.strip}").to_json_object
      end
    end
  end
end
