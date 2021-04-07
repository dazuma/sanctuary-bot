include :bundler
include :exec, e: true

def run
  exec(["functions-framework-ruby", "--target", "discord_webhook"])
end
