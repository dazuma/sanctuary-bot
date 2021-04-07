module SanctuaryBot
  module BibleApi
    class Book
      def initialize(id:, name:)
        @id = id
        @name = name
        @match_name = name.downcase.tr(" ", "")
      end

      attr_reader :id
      attr_reader :name
      attr_reader :match_name

      class << self
        def find(name)
          subexp = name.downcase.gsub(/[^1-9a-z]/, "").split("").join(".*?")
          regexp = Regexp.new("^#{subexp}")
          best = nil
          best_score = 100.0
          @all.each do |book|
            m = regexp.match(book.match_name)
            next unless m
            score = m[0].length.to_f * (1.0 - 1.0 / book.match_name.length)
            if score < best_score
              best = book
              best_score = score
            end
          end
          best
        end
      end

      @all = [
        new(id: "GEN", name: "Genesis"),
        new(id: "EXO", name: "Exodus"),
        new(id: "LEV", name: "Leviticus"),
        new(id: "NUM", name: "Numbers"),
        new(id: "DEU", name: "Deuteronomy"),
        new(id: "JOS", name: "Joshua"),
        new(id: "JDG", name: "Judges"),
        new(id: "RUT", name: "Ruth"),
        new(id: "1SA", name: "1 Samuel"),
        new(id: "2SA", name: "2 Samuel"),
        new(id: "1KI", name: "1 Kings"),
        new(id: "2KI", name: "2 Kings"),
        new(id: "1CH", name: "1 Chronicles"),
        new(id: "2CH", name: "2 Chronicles"),
        new(id: "EZR", name: "Ezra"),
        new(id: "NEH", name: "Nehemiah"),
        new(id: "EST", name: "Esther"),
        new(id: "JOB", name: "Job"),
        new(id: "PSA", name: "Psalms"),
        new(id: "PRO", name: "Proverbs"),
        new(id: "ECC", name: "Ecclesiastes"),
        new(id: "SNG", name: "Song of Songs"),
        new(id: "ISA", name: "Isaiah"),
        new(id: "JER", name: "Jeremiah"),
        new(id: "LAM", name: "Lamentations"),
        new(id: "EZK", name: "Ezekiel"),
        new(id: "DAN", name: "Daniel"),
        new(id: "HOS", name: "Hosea"),
        new(id: "JOL", name: "Joel"),
        new(id: "AMO", name: "Amos"),
        new(id: "OBA", name: "Obadiah"),
        new(id: "JON", name: "Jonah"),
        new(id: "MIC", name: "Micah"),
        new(id: "NAM", name: "Nahum"),
        new(id: "HAB", name: "Habakkuk"),
        new(id: "ZEP", name: "Zephaniah"),
        new(id: "HAG", name: "Haggai"),
        new(id: "ZEC", name: "Zechariah"),
        new(id: "MAL", name: "Malachi"),
        new(id: "MAT", name: "Matthew"),
        new(id: "MRK", name: "Mark"),
        new(id: "LUK", name: "Luke"),
        new(id: "JHN", name: "John"),
        new(id: "ACT", name: "Acts"),
        new(id: "ROM", name: "Romans"),
        new(id: "1CO", name: "1 Corinthians"),
        new(id: "2CO", name: "2 Corinthians"),
        new(id: "GAL", name: "Galatians"),
        new(id: "EPH", name: "Ephesians"),
        new(id: "PHP", name: "Philippians"),
        new(id: "COL", name: "Colossians"),
        new(id: "1TH", name: "1 Thessalonians"),
        new(id: "2TH", name: "2 Thessalonians"),
        new(id: "1TI", name: "1 Timothy"),
        new(id: "2TI", name: "2 Timothy"),
        new(id: "TIT", name: "Titus"),
        new(id: "PHM", name: "Philemon"),
        new(id: "HEB", name: "Hebrews"),
        new(id: "JAS", name: "James"),
        new(id: "1PE", name: "1 Peter"),
        new(id: "2PE", name: "2 Peter"),
        new(id: "1JN", name: "1 John"),
        new(id: "2JN", name: "2 John"),
        new(id: "3JN", name: "3 John"),
        new(id: "JUD", name: "Jude"),
        new(id: "REV", name: "Revelation")
      ]
    end
  end
end
