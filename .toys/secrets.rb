tool "upload" do
  include :bundler

  def run
    require "sanctuary_bot"
    SanctuaryBot.logger = logger
    SanctuaryBot.config.upload_secure_file
  end
end

tool "download" do
  include :bundler

  def run
    require "sanctuary_bot"
    SanctuaryBot.logger = logger
    SanctuaryBot.config.write_secure_file
  end
end

tool "grant-build-access" do
  include :bundler
  include :exec, e: true

  def run
    require "sanctuary_bot"
    SanctuaryBot.logger = logger
    config = SanctuaryBot.config
    exec(["gcloud", "secrets", "add-iam-policy-binding", config.secret_name,
          "--project", config.gcp_project_id,
          "--role", "roles/secretmanager.secretAccessor",
          "--member", "serviceAccount:#{config.gcp_project_number}@cloudbuild.gserviceaccount.com"])
  end
end

tool "grant-runtime-access" do
  include :bundler
  include :exec, e: true

  def run
    require "sanctuary_bot"
    SanctuaryBot.logger = logger
    config = SanctuaryBot.config
    exec(["gcloud", "secrets", "add-iam-policy-binding", config.secret_name,
          "--project", config.gcp_project_id,
          "--role", "roles/secretmanager.secretAccessor",
          "--member", "serviceAccount:#{config.gcp_project_id}@appspot.gserviceaccount.com"])
  end
end
