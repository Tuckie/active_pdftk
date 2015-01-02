require 'date'
require 'ostruct'

# a module that handles the parsing of pdftk's dump_dat
#
module ActivePdftk

  # a hash that has some utility accessor methods to retreive
  # the key fields from the PDF metadata as typed values (string,int,datatime)
  class MetaData < Hash

    def number_of_pages
      self["NumberOfPages"].to_i
    end

    def author
      self["Author"]
    end

    def creator
      self["Creator"]
    end

    def producer
      self["Producer"]
    end

    def title
      self["Title"]
    end

    def mod_date
      parse_date self["ModDate"]
    end

    def creation_date
      parse_date self["CreationDate"]
    end

    def bookmarks
      self["bookmarks"]
    end

    private 

      def parse_date raw
        key, raw_date = raw.split(":")
        date = raw_date[0..-4] # strip of '00'
        DateTime.parse(date)
      end

  end

  # the parser module that parses an input (fileref, stringio) and
  # returns a MetaData object (special kind of hash).
  # the resulting hash typicalle contains values for 
  # - Author
  # - Producer
  # - Creator
  # - Title
  # - ModDate
  # - CreationDate
  # - NumberOfPages
  class MetaDataParser

    def initialize
      @pdftk = Wrapper.new
    end

    def parse(input)
      raw_data = @pdftk.dump_data(input)
      lines = raw_data.read.split("\n")
      meta_data = MetaData.new
      new_key = nil
      new_bookmark_title = ""
      new_bookmark_level = 0
      meta_data["bookmarks"] = []
      lines.each do |line|
        key, value = line.split(": ")
        case key
          when "InfoBegin"
            # do nothing
          when "InfoKey"
            new_key = value
          when "InfoValue"
            meta_data[new_key] = value
          when "BookmarkTitle"
            new_bookmark_title = value
          when "BookmarkLevel"
            new_bookmark_level = value.to_i
          when "BookmarkPageNumber"
            new_bookmark_page_number = value.to_i
            meta_data["bookmarks"].push(OpenStruct.new(level: new_bookmark_level, title: new_bookmark_title, page: new_bookmark_page_number))
          else 
            meta_data[key] = value unless value.nil?
        end 
      end
      meta_data
    end

end
