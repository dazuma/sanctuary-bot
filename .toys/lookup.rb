required_arg :reference
flag :type, accept: String
flag :output, default: "raw"
flag :split, accept: Integer

include :bundler

def run
  require "sanctuary_bot"
  bible_client = SanctuaryBot.bible_api_client
  pass_id = SanctuaryBot::BibleApi::Passage.to_id(reference) rescue reference
  passage = bible_client.passage(pass_id: pass_id, type: type)
  passages = split ? passage.split(max_length: split) : [passage]

  case output
  when "raw"
    passages.each do |passage|
      puts JSON.pretty_generate(passage.raw_data)
    end
  when "content"
    passages.each do |passage|
      puts passage.full_reference
      puts passage.content
    end
  else
    puts "UNKNOWN OUTPUT TYPE"
  end
end
