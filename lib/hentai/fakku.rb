require 'open-uri'
require 'nokogiri'
require 'rest-client'
require 'json'

module Hentai
  module Fakku

    # Constants
    BASE_URL = "https://www.fakku.net"
    BASE_API_URL = "https://api.fakku.net"

    # Class defs

    class Doujin
      attr_accessor :upload_date, :num_favorites, :title, :cover, :sample,
                    :language, :artist, :tags, :category, :url, :num_comments,
                    :filesize, :num_pages, :uploader, :parody

      def initialize(hash)
        #fakku does NOT let unpaid users access it's pages.  We can only index it's results.
        @upload_date = hash["content_date"]
        @num_favorites = hash["content_favorites"]
        @title = hash["content_name"]
        @cover = Picture.new hash["content_images"]["cover"]
        @sample = Picture.new hash["content_images"]["sample"]
        @language = hash["content_language"]
        @tags = get_tags hash["content_tags"]
        @category = hash["content_category"]
        @url = hash["content_url"]
        @num_comments = hash["comments"]
        @filesize = hash["content_filesize"]
        @num_pages = hash["content_pages"]
        @uploader = Property.new(name: hash["content_poster"],
                             url: hash["content_poster_url"])

        # TODO: Find out how to deal with the following consistently
        # these fields may have multiple attributes per each, E.G. can have
        # multiple artists

        # @parody = hash["content_series"]["attribute"]
        # @publisher = Property.new(name: hash["content_publishers"]["attribute"],
        #                      url: hash["content_publishers"]["attribute_link"])
        # @artist = Property.new(name: hash["content_artists"]["attribute"],
        #                       url: hash["content_artists"]["attribute_link"])

      end

      private

      def get_tags(hash)
        tags = []
        hash.each do |tag|
          tags.push Tag.new(tag)
        end

        tags

      end

    end

    # Fakku has a lot of data with an attribute name and url, such as an
    # Artist or User.  Tags are the same, but have been moved to their own
    # class for easier readability.
    class Property
      attr_accessor :name, :url

      def initialize(name:, url:)
        @name = name
        @url = url
      end

    end

    class Tag
      attr_accessor :name, :url

      def initialize(hash)
        @name = hash["attribute"]
        @url = BASE_URL + hash["attribute_link"]
      end
    end

    class Picture
      attr_accessor :url

      def initialize(url)
        @url = url
      end
    end

    # Module methods
    def Fakku.search(tags: )

      # Fakku's search API route is currently broken, so we will use scraping to get any search terms.
      # the tags route is still functional, but we're going to use scraping universally for consistency

      # whitespace must be converted into dashes per each search term
      # we need to join our tags array the URL encoded space character
      # for example, a search of [dark skin, color] would result in dark-skin%20color
      tags.each { |tag| tag.gsub!(/\s+/,"-") }
      tags = tags.join("%20")
      # open url
      page = Nokogiri::HTML(open("#{BASE_URL}/search/#{tags}"))

      # we first need to all doujins on a page. they look like this
      # <div class="manga">
      #   <div class="images">
      #     <a href="{link_to_doujin}">
      #       <img class="cover" src="//t.fakku.net/images/images/c/thumb.jpg" />
      #     </a>
      #   </div>
      # </div>

      doujins = []

      page.css(".manga .images a").each do |link|

        # Now that we have a link, we need to follow "BASE_API_URL + link"
        # to access the API

        json = JSON.parse(RestClient.get("#{BASE_API_URL}/#{link.attribute("href")}"))
        doujin = Doujin.new(json["content"])
        doujins.push doujin

      end

      doujins

    end
  end
end
