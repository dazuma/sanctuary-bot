require "helper"

describe SanctuaryBot::Webhook::Help do
  let(:help) { SanctuaryBot::Webhook::Help.new }

  it "handles help commands" do
    interaction = SanctuaryBot::Webhook::Interaction.new({
      "type": 2,
      "data" => {
        "name" => "help",
        "options" => [
          {
            "name" => "topic",
            "value" => "me"
          }
        ]
      }
    })
    assert(help.should_handle?(interaction))
  end

  it "does not handle word commands" do
    interaction = SanctuaryBot::Webhook::Interaction.new({
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
    })
    refute(help.should_handle?(interaction))
  end

  it "responds with word help" do
    interaction = SanctuaryBot::Webhook::Interaction.new({
      "type": 2,
      "data" => {
        "name" => "help",
        "options" => [
          {
            "name" => "topic",
            "value" => "scripture"
          }
        ]
      }
    })
    response = help.handle(interaction)
    assert_equal(4, response["type"])
    assert_match(%r{command looks up and displays a passage}, response["data"]["content"])
  end

  it "responds with main help" do
    interaction = SanctuaryBot::Webhook::Interaction.new({
      "type": 2,
      "data" => {
        "name" => "help",
        "options" => []
      }
    })
    response = help.handle(interaction)
    assert_equal(4, response["type"])
    assert_match(%r{I hang out here, and you can tell me to do stuff}, response["data"]["content"])
  end
end
