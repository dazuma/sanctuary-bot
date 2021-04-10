module SanctuaryBot
  module BibleApi
    class Passage
      class VerseData
        def initialize(book:, chapter:, verse:, start:, chapter_start: false)
          @book = book
          @chapter = chapter
          @verse = verse
          @content_parts = []
          add(start || :z)
          verse_header = chapter_start ? "#{chapter}:#{verse}" : verse.to_s
          @content_parts << "_[#{verse_header}]_ "
        end

        attr_reader :book
        attr_reader :chapter
        attr_reader :verse
        
        def content
          @content ||= @content_parts.join.chomp(" ")
        end

        def add(part)
          fragment =
            case part
            when :p
              "\n\t"
            when :a
              "\n\t\t"
            when :b
              "\n\t\t\t"
            when :z
              " "
            when String
              part
            end
          @content_parts << fragment if fragment
          @content = nil
          self
        end
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

      def self.from_data(data:, translation: nil, logger: nil)
        new(data: data, translation: translation, logger: logger)
      end

      def initialize(translation: nil, logger: nil,
                     verses: nil, data: nil)
        @translation = translation || Translation.default
        @logger = logger || SanctuaryBot.logger
        @raw_data = data
        if data
          init_from_data(data)
        else
          init_from_verses(verses)
        end
      end

      attr_reader :translation
      attr_reader :book
      attr_reader :verses
      attr_reader :raw_data

      def content
        @content ||= @verses.map(&:content).join.slice(1..-1)
      end

      def reference
        @reference ||=
          if @first_chapter != @last_chapter
            "#{@book.name} #{@first_chapter}:#{@first_verse}-#{@last_chapter}:#{@last_verse}"
          elsif @first_verse != @last_verse
            "#{@book.name} #{@first_chapter}:#{@first_verse}-#{@last_verse}"
          else
            "#{@book.name} #{@first_chapter}:#{@first_verse}"
          end
      end

      def full_reference
        "#{reference} (#{translation.abbreviation})"
      end

      def full_content
        "#{full_reference}\n#{content}"
      end

      def to_s
        full_reference
      end

      def split(max_length:)
        return [self] if content.length <= max_length
        groups = [[]]
        cur_length = -1
        @verses.each do |vd|
          cur_length += vd.content.length
          if cur_length > max_length && !groups.last.empty?
            groups << []
            cur_length = vd.content.length - 1
          end
          groups.last << vd
        end
        groups.map do |group|
          Passage.new(translation: translation, logger: @logger, verses: group)
        end
      end

      private

      def init_from_data(data)
        @book = Book.find(data["bookId"])
        if data["id"] =~ /^\w\w\w\.(\d+)\.(\d+)(?:-\w\w\w\.(\d+).(\d+))$/
          m = Regexp.last_match
          @first_chapter = m[1].to_i
          @first_verse = m[2].to_i
          @last_chapter = (m[3] || @first_chapter).to_i
          @last_verse = (m[4] || @first_verse).to_i
          @reference = nil
        else
          @first_chapter = @first_verse = @last_chapter = @last_verse = nil
          @reference = data["reference"]
        end
        content = data["content"]
        if content.is_a?(String)
          @content = content
          @verses = nil
        else
          @verses = []
          @line_starter = nil
          parse_json(content)
          @content = nil
        end
      end

      def init_from_verses(verses)
        @first_chapter = verses.first.chapter
        @first_verse = verses.first.verse
        @last_chapter = verses.last.chapter
        @last_verse = verses.last.verse
        @book = verses.first.book
        @verses = verses
        @content = nil
      end

      def parse_json(node)
        if node.is_a?(Array)
          node.each { |elem| parse_json(elem) }
        elsif node["name"] == "para"
          style = node["attrs"]["style"]
          @line_starter =
            case style
            when "p"
              :p
            when "q1"
              :a
            when "q2"
              :b
            else
              @logger.error("Unknown paragraph style: #{style.inspect}")
              :p
            end
          parse_json(node["items"])
        elsif node["name"] == "verse"
          sid = node["attrs"]["sid"]
          if sid =~ /^\w\w\w\s*(\d+):(\d+)$/
            chapter = Regexp.last_match[1].to_i
            verse = Regexp.last_match[2].to_i
            chapter_start = @verses.empty? || @verses.last.chapter != chapter
            verse_data = VerseData.new(book: @book, chapter: chapter, verse: verse,
                                       start: @line_starter, chapter_start: chapter_start)
            @line_starter = nil
            @verses << verse_data
          else
            @logger.error("Unrecognized sid: #{sid.inspect}")
          end
        elsif node["name"] == "char"
          parse_json(node["items"])
        elsif node["type"] == "text"
          @verses.last&.add(@line_starter)
          @line_starter = nil
          @verses.last&.add(node["text"])
        else
          @logger.error("Unparseable node: #{node.inspect}")
        end
      end
    end
  end
end
