require 'open-uri'
require 'nokogiri'
require 'rest-client'
require 'json'

module Hentai
  module NHentai

    # Constants
    BASE_URL = "http://nhentai.net"
    IMAGE_BASE_URL = "http://i.nhentai.net"
    THUMB_BASE_URL = "http://t.nhentai.net"

    # Class defs

    class Doujin
      attr_accessor :upload_date, :num_favorites, :media_id, :title, :cover,
                    :pages, :language, :artist, :tags, :group, :parody, 
                    :category, :scanlator, :id, :num_pages

      def initialize(hash)
        @upload_date = hash["upload_date"]
        @num_favorites = hash["num_favorites"]
        @media_id = hash["media_id"]
        @title = Title.new hash["title"]
        @cover = Picture.new hash["images"]["cover"], 
                THUMB_BASE_URL + "/galleries/" + media_id + "/thumb.jpg"
        @pages = get_pages hash["images"]["pages"], media_id

        # Language, artist, characters, category, tags, group, parody, and possibly
        # others are treated as "tags" in the shitty JSON API. Each of these
        # attributes can have multiple values. Need to figure out a good way to
        # handle this.

        @id = hash["id"]
        @num_pages = hash["num_pages"]
      end

      private
        def get_pages(images, media_id)
          pages = []
          images.each_with_index do |image, index|
            # XXX: check image type
            pages.push Picture.new image, 
                      IMAGE_BASE_URL + "/galleries/" + media_id + 
                      "/" + (index+1).to_s + ".jpg"
          end

          pages
        end

    end

    class Title
      attr_accessor :english, :japanese

      def initialize(hash)
        @english = hash["english"]
        @japanese = hash["japanese"]
      end

    end

    class Picture
      attr_accessor :height, :width, :type, :url

      def initialize(hash, url)
        @height = hash["h"]
        @width = hash["w"]
        @type = hash["t"]
        @url = url
      end
    end

    # Module methods
    def NHentai.search(options = {})
      tag = options.fetch :tag

      # open url
      page = Nokogiri::HTML(open(BASE_URL + "/tag/" + tag))

      # we first need to all doujins on a page. they look like this
      #
      #    <div class="gallery" data-tags="8010 10988 22942 29013">
      #        <a href="/g/154483/" class="cover">
      #            <img src="//t.nhentai.net/galleries/894501/thumb.jpg" width="250" height="359" alt="..." />
      #            <div class="caption">[Anthology] LQ -Little Queen- Vol. 6 [Digital]</div>
      #        </a>
      #    </div>
      #
      # We need to gather all hrefs to do further digging.
      # Therefore, we should grab the href with class of "cover"

      doujins = []

      page.css(".cover").each do |link|

        # Now that we have a link, we need to follow "BASE_URL + link + json" 
        # to access the bad API
        #
        # `link' looks like: /g/154427/

        json = JSON.parse(RestClient.get(BASE_URL + link.attribute("href") + "json"))
        
        doujin = Doujin.new(json)

        doujins.push doujin

      end

     doujins 

    end

  end
end
