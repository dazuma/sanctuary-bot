tool "create-topic" do
  flag :staging

  include :bundler
  include :exec, e: true

  def run
    require "sanctuary_bot"
    SanctuaryBot.logger = logger
    SanctuaryBot.sanctuary_env = staging ? "staging" : "prod"
    config = SanctuaryBot.config
    result = exec(["gcloud", "pubsub", "topics", "describe",
                   "--project", config.gcp_project_id,
                   config.gcp_pubsub_topic],
                  err: :null, out: :null, e: false)
    if result.success?
      puts "Topic already present."
    else
      exec(["gcloud", "pubsub", "topics", "create",
            "--project", config.gcp_project_id,
            "--message-storage-policy-allowed-regions", config.gcp_region,
            config.gcp_pubsub_topic])
      puts "Topic created."
    end
  end
end
