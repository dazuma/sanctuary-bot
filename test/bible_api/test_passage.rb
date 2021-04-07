require "helper"

describe SanctuaryBot::BibleApi::Passage do
  describe "to_id" do
    it "Recognizes a range across multiple chapters" do
      id = SanctuaryBot::BibleApi::Passage.to_id("Matt 1:2-3:4")
      assert_equal("MAT.1.2-MAT.3.4", id)
    end

    it "Recognizes a range in the same chapter" do
      id = SanctuaryBot::BibleApi::Passage.to_id("Matt 1:2-3")
      assert_equal("MAT.1.2-MAT.1.3", id)
    end

    it "Recognizes a single verse" do
      id = SanctuaryBot::BibleApi::Passage.to_id("Matt 1:2")
      assert_equal("MAT.1.2", id)
    end

    it "Recognizes an entire chapter" do
      id = SanctuaryBot::BibleApi::Passage.to_id("Matt 1")
      assert_equal("MAT.1", id)
    end

    it "Recognizes a range of chapters" do
      id = SanctuaryBot::BibleApi::Passage.to_id("Matt 1-3")
      assert_equal("MAT.1-MAT.3", id)
    end

    it "Recognizes range across multiple chapters starting with an entire chapter" do
      id = SanctuaryBot::BibleApi::Passage.to_id("Matt 1-3:4")
      assert_equal("MAT.1.1-MAT.3.4", id)
    end

    it "Recognizes unusual whitespace" do
      id = SanctuaryBot::BibleApi::Passage.to_id(" Matt1 :  2 - 3  : 4 ")
      assert_equal("MAT.1.2-MAT.3.4", id)
    end
  end
end
