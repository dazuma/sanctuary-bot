module SanctuaryBot
  module BibleApi
    class Translation
      def initialize(data:)
        @data = data
        @id = data["id"]
        @name = data["name"]
        @abbreviation = data["abbreviation"]
      end

      attr_reader :id
      attr_reader :name
      attr_reader :abbreviation

      def to_s
        "#{name} (id=#{id})"
      end

      def hash
        id.hash
      end

      def get(name)
        @data[name.to_s]
      end

      def self.parse(data)
        new(data: data)
      end

      def self.parse_multi(data)
        data.map { |elem| parse(elem) }
      end

      class << self
        def default
          @default ||= new(data: {
            "id" => "9879dbb7cfe39e4d-01",
            "name" => "World English Bible",
            "abbreviation" => "WEB",
          })
        end
      end
    end
  end
end
