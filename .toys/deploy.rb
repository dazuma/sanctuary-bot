flag :function_name, default: "discord_webhook"

include :exec, e: true

def run
  require "sanctuary_bot"
  SanctuaryBot.logger = logger
  config = SanctuaryBot.config
  exec(["gcloud", "functions", "deploy", config.gcp_function_name,
        "--project", config.gcp_project_id,
        "--entry-point", function_name,
        "--runtime=ruby27", "--trigger-http", "--allow-unauthenticated"])
end
