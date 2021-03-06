
module SteamcmdServerList

  require 'httparty'
  require 'nokogiri'
  require 'active_support/inflector'
  require 'yaml'


  class Scraper
    include ActiveSupport::Inflector
    attr_accessor :games


    def initialize(url)
      config = YAML.load_file('config.yaml')

      @url = url
      document = HTTParty.get(config['url'])
      @page ||= Nokogiri::HTML(document)
      @table = @page.at('table')
      @games ||= []
      @headings ||= get_headings
      scraper.process_table

    end


    def convert_heading(string)
      string.strip.downcase.parameterize.underscore.to_sym
    end

    def get_headings
      headings = []
      @page.xpath("//th").each do |heading|
        heading = convert_heading(heading.text)
        if !(headings.include? heading)
          headings << heading
        end
      end
      headings
    end

    def process_table
      @page.xpath("//tr").each do |table_row|
        row = process_row table_row.text
        add_game row
      end
    end

    def process_row(row)
      new_row = []
      row = row.strip.split("\n")
      row.each do |r|
        new_row << r.strip
      end
      new_row
      # pp row
    end

    def add_game(attributes)
      game = {}
      if ! (attributes.any? { |attribute| @headings.include? convert_heading(attribute)})
        attributes.zip(@headings).each do |attribute, heading|
          game[heading] = attribute || ""
        end
        @games << game
      end
    end

    def write_to_file(filename, data)
      File.open(filename, 'w') do |file|
        file.write(data.to_yaml)

      end
    end

    def find_id(name)
      found = {}
      games.each do |game|
        if game['server'] == name.lower() and !(found)
          found = game
        end
      end
      found
    end

  end
end
