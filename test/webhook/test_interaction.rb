require "helper"

describe SanctuaryBot::Webhook::Interaction do
  include FunctionsFramework::Testing

  describe "signatures" do
    let(:signing_key) { Ed25519::SigningKey.generate }
    let(:verification_key) { signing_key.verify_key }

    it "recognizes a valid signature" do
      body = '{"type":1}'
      timestamp = "123456789"
      signature = signing_key.sign(timestamp + body).unpack1("H*")
      headers = {
        "X-Signature-Ed25519" => signature,
        "X-Signature-Timestamp" => timestamp
      }
      request = make_post_request("http://example.com", body, headers)
      interaction = SanctuaryBot::Webhook::Interaction.from_request(request, verification_key: verification_key)
      assert_nil(interaction.verification_error)
    end

    it "recognizes an invalid signature" do
      body = '{"type":1}'
      timestamp = "123456789"
      signature = signing_key.sign(timestamp + body).unpack1("H*")
      headers = {
        "X-Signature-Ed25519" => signature,
        "X-Signature-Timestamp" => "123456780"
      }
      request = make_post_request("http://example.com", body, headers)
      interaction = SanctuaryBot::Webhook::Interaction.from_request(request, verification_key: verification_key)
      refute_nil(interaction.verification_error)
    end

    it "can disable verification" do
      body = '{"type":1}'
      request = make_post_request("http://example.com", body)
      interaction = SanctuaryBot::Webhook::Interaction.from_request(request, verification_key: :disable_verification)
      assert_nil(interaction.verification_error)
    end
  end

  describe "parsing" do
    it "recognizes bad json" do
      body = "zzz"
      request = make_post_request("http://example.com", body)
      interaction = SanctuaryBot::Webhook::Interaction.from_request(request, verification_key: :disable_verification)
      refute_nil(interaction.format_error)
    end

    it "parses command data with options" do
      data = {
        "type": 2,
        "data" => {
          "name" => "lookup",
          "options" => [
            {
              "name" => "reference",
              "value" => "Matt 1:1"
            }
          ]
        }
      }
      request = make_post_request("http://example.com", JSON.dump(data))
      interaction = SanctuaryBot::Webhook::Interaction.from_request(request, verification_key: :disable_verification)
      assert_nil(interaction.format_error)
      assert_equal("lookup", interaction.command_data.name)
      assert_equal("Matt 1:1", interaction.command_data.option("reference"))
    end
  end
end
