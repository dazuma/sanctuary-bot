flag :staging
required_arg :which, accept: ["webhook", "pubsub", "all"]

include :exec, e: true
include :terminal

def run
  require "sanctuary_bot"
  SanctuaryBot.sanctuary_env = staging ? "staging" : "prod"
  SanctuaryBot.logger = logger
  config = SanctuaryBot.config

  if ["pubsub", "all"].include?(which)
    puts "Deploying pubsub subscriber...", :bold
    exec(["gcloud", "functions", "deploy", config.gcp_pubsub_function_name,
          "--project", config.gcp_project_id, "--region", config.gcp_region,
          "--entry-point", "discord_pubsub",
          "--set-build-env-vars", "SANCTUARY_ENV=#{SanctuaryBot.sanctuary_env}",
          "--set-env-vars", "SANCTUARY_ENV=#{SanctuaryBot.sanctuary_env}",
          "--trigger-topic", config.gcp_pubsub_topic,
          "--runtime=ruby27", "--allow-unauthenticated"])
  end

  if ["webhook", "all"].include?(which)
    puts "Deploying webhook...", :bold
    exec(["gcloud", "functions", "deploy", config.gcp_function_name,
          "--project", config.gcp_project_id, "--region", config.gcp_region,
          "--entry-point", "discord_webhook",
          "--set-build-env-vars", "SANCTUARY_ENV=#{SanctuaryBot.sanctuary_env}",
          "--set-env-vars", "SANCTUARY_ENV=#{SanctuaryBot.sanctuary_env}",
          "--runtime=ruby27", "--trigger-http", "--allow-unauthenticated"])
  end
end
