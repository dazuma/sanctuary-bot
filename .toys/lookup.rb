required_arg :reference
flag :type, default: "text"

include :bundler

def run
  require "sanctuary_bot"
  bible_client = SanctuaryBot.bible_api_client
  pass_id = SanctuaryBot::BibleApi::Passage.to_id(reference) rescue reference
  passage = bible_client.passage(pass_id: pass_id, type: type)
  puts JSON.pretty_generate(passage.raw_data)
end
