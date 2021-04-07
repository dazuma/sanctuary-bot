tool "create" do
  exactly_one do
    flag :lookup_command, "--lookup-command[=NAME]"
    flag :help_command, "--help-command[=NAME]"
  end

  include :bundler

  def run
    require "sanctuary_bot"
    SanctuaryBot.logger = logger
    if lookup_command
      name = lookup_command.is_a?(String) ? lookup_command : SanctuaryBot.config.lookup_command
      spec = SanctuaryBot::Webhook::Lookup::command_spec(name)
    elsif help_command
      name = help_command.is_a?(String) ? help_command : SanctuaryBot.config.help_command
      spec = SanctuaryBot::Webhook::Help::command_spec(name)
    end
    client = SanctuaryBot::DiscordApi::Client.new
    result = client.create_guild_command(spec)
    puts JSON.pretty_generate(result)
  end  
end

tool "list" do
  include :bundler

  def run
    require "sanctuary_bot"
    SanctuaryBot.logger = logger
    client = SanctuaryBot::DiscordApi::Client.new
    result = client.list_guild_commands
    puts JSON.pretty_generate(result)
  end  
end

tool "get" do
  required_arg :name

  include :bundler

  def run
    require "sanctuary_bot"
    SanctuaryBot.logger = logger
    client = SanctuaryBot::DiscordApi::Client.new
    list = client.list_guild_commands
    result = list.find { |elem| elem["name"] == name }
    puts JSON.pretty_generate(result)
  end  
end

tool "delete" do
  required_arg :name

  include :bundler

  def run
    require "sanctuary_bot"
    SanctuaryBot.logger = logger
    client = SanctuaryBot::DiscordApi::Client.new
    list = client.list_guild_commands
    result = list.find { |elem| elem["name"] == name }
    if result.nil?
      puts "Unable to find command named #{name}"
      exit 1
    end
    result = client.delete_guild_command(result["id"])
    puts JSON.pretty_generate(result)
  end  
end
