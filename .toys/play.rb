include :bundler

def run
  require "sanctuary_bot"

  client = SanctuaryBot::DiscordApi::Client.new
  result = client.list_commands
  puts JSON.pretty_generate(result)
  exit

  command = {
    "name" => "lookup",
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
  result = client.create_guild_command(command)
  puts JSON.pretty_generate(result)
end
