flag :staging

include :exec, e: true

def run
  require "sanctuary_bot"
  SanctuaryBot.sanctuary_env = staging ? "staging" : "prod"
  SanctuaryBot.logger = logger
  config = SanctuaryBot.config
  exec(["gcloud", "functions", "deploy", config.gcp_function_name,
        "--project", config.gcp_project_id,
        "--entry-point", "discord_webhook",
        "--set-build-env-vars", "SANCTUARY_ENV=#{SanctuaryBot.sanctuary_env}",
        "--set-env-vars", "SANCTUARY_ENV=#{SanctuaryBot.sanctuary_env}",
        "--runtime=ruby27", "--trigger-http", "--allow-unauthenticated"])
end
