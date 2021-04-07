require "helper"

describe SanctuaryBot::Webhook::Responder do
  include FunctionsFramework::Testing

  let(:signing_key) { Ed25519::SigningKey.generate }
  let(:verification_key) { signing_key.verify_key }
  let(:responder) { SanctuaryBot::Webhook::Responder.new(verification_key: verification_key) }

  it "pongs" do
    body = '{"type":1}'
    timestamp = "123456789"
    signature = signing_key.sign(timestamp + body).unpack1("H*")
    headers = {
      "X-Signature-Ed25519" => signature,
      "X-Signature-Timestamp" => timestamp
    }
    request = make_post_request("http://example.com", body, headers)
    response = responder.respond(request)
    assert_equal({"type" => 1}, response)
  end

  it "errors from an invalid signature" do
    body = '{"type":1}'
    timestamp = "123456789"
    signature = signing_key.sign(timestamp + body).unpack1("H*")
    headers = {
      "X-Signature-Ed25519" => signature,
      "X-Signature-Timestamp" => timestamp + timestamp
    }
    request = make_post_request("http://example.com", body, headers)
    response = responder.respond(request)
    assert_equal(401, response.first)
  end

  it "errors from an invalid format" do
    body = 'zzz'
    timestamp = "123456789"
    signature = signing_key.sign(timestamp + body).unpack1("H*")
    headers = {
      "X-Signature-Ed25519" => signature,
      "X-Signature-Timestamp" => timestamp
    }
    request = make_post_request("http://example.com", body, headers)
    response = responder.respond(request)
    assert_equal(400, response.first)
  end

  it "errors from no matching handler" do
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
    response = responder.respond(request)
    assert_equal(500, response.first)
  end

  it "returns from a matching handler" do
    mock_bible_client = Minitest::Mock.new
    passage_data = {
      "bookId" => "MAT",
      "reference" => "Matthew 1:1",
      "content" => "hello"
    }
    passage = SanctuaryBot::BibleApi::Passage.new(data: passage_data)
    mock_bible_client.expect(:passage, passage, [{reference: "Matt 1:1"}])
    lookup = SanctuaryBot::Webhook::Lookup.new(bible_api_client: mock_bible_client)
    responder.add_handler(lookup)
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
    response = responder.respond(request)
    response_data = JSON.parse(response.last.first)
    assert_equal(4, response_data["type"])
    assert_equal(passage.full_content, response_data["data"]["content"])
  end
end
