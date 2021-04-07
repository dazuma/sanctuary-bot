require "helper"

describe "webhook function" do
  include FunctionsFramework::Testing

  it "looks up Matthew 1" do
    load_temporary("app.rb") do
      signing_key = Ed25519::SigningKey.generate
      verification_key = signing_key.verify_key

      lookup = SanctuaryBot::Webhook::Lookup.new
      responder = SanctuaryBot::Webhook::Responder.new(verification_key: verification_key).add_handler(lookup)

      data = {
        "type": 2,
        "data" => {
          "name" => "word",
          "options" => [
            {
              "name" => "reference",
              "value" => "Matt 1:1"
            }
          ]
        }
      }
      body = JSON.dump(data)
      timestamp = "123456789"
      signature = signing_key.sign(timestamp + body).unpack1("H*")
      headers = {
        "X-Signature-Ed25519" => signature,
        "X-Signature-Timestamp" => timestamp
      }
      request = make_post_request("http://example.com", body, headers)

      response = call_http("discord_webhook", request, globals: {responder: responder})
      assert_equal(200, response.status)
      response_data = JSON.parse(response.body.join)
      assert_equal(4, response_data["type"])
      assert_match(%r{The book of the genealogy of Jesus Christ}, response_data["data"]["content"])
      assert_equal([], response_data["data"]["allowed_mentions"]["parse"])
    end
  end
end
