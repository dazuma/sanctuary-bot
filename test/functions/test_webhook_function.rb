require "helper"

describe "webhook function" do
  include FunctionsFramework::Testing

  it "looks up Matthew 1" do
    load_temporary("app.rb") do
      signing_key = Ed25519::SigningKey.generate
      verification_key = signing_key.verify_key

      passage_data = {
        "bookId" => "MAT",
        "reference" => "Matthew 1:1",
        "content" => "hello"
      }
      passage = SanctuaryBot::BibleApi::Passage.new(data: passage_data)
      mock_bible_client = Minitest::Mock.new
      mock_bible_client.expect(:passage, passage, [{reference: "Matt 1:1"}])
      lookup = SanctuaryBot::Webhook::Lookup.new(bible_api_client: mock_bible_client)
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
      mock_bible_client.verify
      assert_equal(200, response.status)
      response_data = JSON.parse(response.body.join)
      assert_equal(4, response_data["type"])
      assert_equal(passage.full_content, response_data["data"]["content"])
      assert_equal([], response_data["data"]["allowed_mentions"]["parse"])
    end
  end

  it "displays help" do
    load_temporary("app.rb") do
      signing_key = Ed25519::SigningKey.generate
      verification_key = signing_key.verify_key

      help = SanctuaryBot::Webhook::Help.new
      responder = SanctuaryBot::Webhook::Responder.new(verification_key: verification_key).add_handler(help)

      data = {
        "type": 2,
        "data" => {
          "name" => "help",
          "options" => [
            {
              "name" => "topic",
              "value" => "word"
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
      assert_match(%r{looks up and displays a passage from scripture}, response_data["data"]["content"])
      assert_equal([], response_data["data"]["allowed_mentions"]["parse"])
    end
  end

  it "responds to pings" do
    load_temporary("app.rb") do
      signing_key = Ed25519::SigningKey.generate
      verification_key = signing_key.verify_key
      responder = SanctuaryBot::Webhook::Responder.new(verification_key: verification_key)

      body = '{"type":1}'
      timestamp = "123456789"
      signature = signing_key.sign(timestamp + body).unpack1("H*")
      headers = {
        "X-Signature-Ed25519" => signature,
        "X-Signature-Timestamp" => timestamp
      }
      request = make_post_request("http://example.com", body, headers)

      response = call_http("discord_webhook", request, globals: {responder: responder})
      assert_equal(200, response.status)
      assert_equal('{"type":1}', response.body.join)
    end
  end
end
