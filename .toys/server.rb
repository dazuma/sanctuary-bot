flag :function_name, default: "discord_webhook"

include :bundler
include :exec, e: true

def run
  exec(["functions-framework-ruby", "--target", function_name])
end
