module SanctuaryBot
  module BibleApi
    class Passage
      def initialize(data:, translation: nil)
        @translation = translation || Translation.default
        @raw_data = data
        @book = Book.find(data["bookId"])
        @reference = data["reference"]
        @content = data["content"]
      end

      attr_reader :translation
      attr_reader :book
      attr_reader :reference
      attr_reader :content
      attr_reader :raw_data

      def full_reference
        "#{reference} (#{translation.abbreviation})"
      end

      def full_content
        "#{full_reference}\n#{content}"
      end

      def to_s
        full_reference
      end

      def self.to_id(str)
        regexp = %r{^(?<book>[a-zA-Z1-9][a-zA-Z]+)(?<a>\d+)(?::(?<b>\d+))?(?:-(?<c>\d+)(?::(?<d>\d+))?)?$}
        match = regexp.match(str.tr(" ", ""))
        unless match
          raise Error, "I didn't understand the Scripture reference. Try something that looks like `Matt 1:1-10`."
        end
        book = Book.find(match[:book])
        raise Error, "I didn't recognize the book name '#{match[:book]}'" unless book
        first_chapter = match[:a].to_i
        if match[:c]
          if match[:d]
            last_chapter = match[:c].to_i
            if last_chapter < first_chapter
              raise Error, "the chapter numbers seemed to go backward from #{first_chapter} to #{last_chapter}"
            end
            first_verse = match[:b] ? match[:b].to_i : 1
            last_verse = match[:d].to_i
            if last_chapter == first_chapter && last_verse < first_verse
              raise Error, "the verse numbers seemed to go backward from #{first_verse} to #{last_verse}"
            end
            "#{book.id}.#{first_chapter}.#{first_verse}-#{book.id}.#{last_chapter}.#{last_verse}"
          elsif match[:b]
            first_verse = match[:b].to_i
            last_verse = match[:c].to_i
            if last_verse < first_verse
              raise Error, "the verse numbers seemed to go backward from #{first_verse} to #{last_verse}"
            end
            "#{book.id}.#{first_chapter}.#{first_verse}-#{book.id}.#{first_chapter}.#{last_verse}"
          else
            last_chapter = match[:c].to_i
            if last_chapter < first_chapter
              raise Error, "the chapter numbers seemed to go backward from #{first_chapter} to #{last_chapter}"
            end
            "#{book.id}.#{first_chapter}-#{book.id}.#{last_chapter}"
          end
        elsif match[:b]
          first_verse = match[:b].to_i
          "#{book.id}.#{first_chapter}.#{first_verse}"
        else
          "#{book.id}.#{first_chapter}"
        end
      end
    end
  end
end
