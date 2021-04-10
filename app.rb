require "functions_framework"

# Require the local lib directory
lib_dir = File.join(__dir__, "lib")
$LOAD_PATH << lib_dir unless $LOAD_PATH.include?(lib_dir)
require "sanctuary_bot"

SanctuaryBot.logger = FunctionsFramework.logger

# At GCF build time, access secrets from secret manager and cache them
# in a local secure file. This ensures we don't have to call secret manager
# during cold start.
unless SanctuaryBot.config.secure_file_exists?
  SanctuaryBot.config.write_secure_file
end

FunctionsFramework.on_startup do
  FunctionsFramework.logger.info("on_startup")
  set_global(:responder) do
    FunctionsFramework.logger.info("creating responder...")
    responder = SanctuaryBot::Webhook::Responder.new
      .add_handler(SanctuaryBot::Webhook::Lookup.new)
      .add_handler(SanctuaryBot::Webhook::Help.new)
    FunctionsFramework.logger.info("Built responder")
    responder
  end
  set_global(:subscriber) do
    FunctionsFramework.logger.info("creating subscriber...")
    subscriber = SanctuaryBot::Webhook::Subscriber.new
    FunctionsFramework.logger.info("Built subscriber")
    subscriber
  end
end

FunctionsFramework.http("discord_webhook") do |request|
  global(:responder).respond(request)
end

FunctionsFramework.cloud_event("discord_pubsub") do |event|
  global(:subscriber).respond(event)
  "OK"
rescue => e
  logger.error(e)
  "ERR"
end
