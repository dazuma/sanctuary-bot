require "helper"

describe SanctuaryBot::BibleApi::Book do
  describe "find" do
    it "finds Genesis by the full name" do
      book = SanctuaryBot::BibleApi::Book.find("Genesis")
      assert_equal("GEN", book.id)
    end

    it "finds Genesis by an abbreviation" do
      book = SanctuaryBot::BibleApi::Book.find("gen")
      assert_equal("GEN", book.id)
    end

    it "finds Matthew by the full name" do
      book = SanctuaryBot::BibleApi::Book.find("Matthew")
      assert_equal("MAT", book.id)
    end

    it "finds Matthew by a split abbreviation" do
      book = SanctuaryBot::BibleApi::Book.find("MT")
      assert_equal("MAT", book.id)
    end

    it "chooses Jonah over John for JON" do
      book = SanctuaryBot::BibleApi::Book.find("JON")
      assert_equal("JON", book.id)
    end

    it "finds 1 Corinthians" do
      book = SanctuaryBot::BibleApi::Book.find("1co")
      assert_equal("1CO", book.id)
    end
  end
end
