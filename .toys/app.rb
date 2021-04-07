tool "register" do
  include :exec

  def run
    require "sanctuary_bot"
    SanctuaryBot.logger = logger
    config = SanctuaryBot.config
    url = "https://discord.com/api/oauth2/authorize?client_id=#{config.discord_client_id}&scope=bot%20applications.commands"
    result = exec(["open", url])
    unless result.success?
      puts "Open the following URL in your browser:"
      puts url
    end
  end
end
