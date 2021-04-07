require "functions_framework"

# Require the local lib directory
lib_dir = File.join(__dir__, "lib")
$LOAD_PATH << lib_dir unless $LOAD_PATH.include?(lib_dir)
require "sanctuary_bot"

# At GCF build time, access secrets from secret manager and cache them
# in a local secure file. This ensures we don't have to call secret manager
# during cold start.
unless SanctuaryBot.config.secure_file_exists?
  SanctuaryBot.logger = FunctionsFramework.logger
  SanctuaryBot.config.write_secure_file
end

FunctionsFramework.on_startup do
  SanctuaryBot.logger = FunctionsFramework.logger
  set_global(:responder) do
    SanctuaryBot::Webhook::Responder.new
      .add_handler(SanctuaryBot::Webhook::Lookup.new)
      .add_handler(SanctuaryBot::Webhook::Help.new)
  end
end

FunctionsFramework.http("discord_webhook") do |request|
  global(:responder).respond(request)
end
