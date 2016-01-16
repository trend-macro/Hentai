module NHentai
  class Doujin
    attr_accessor :upload_data, :num_favorites, :media_id, :cover, :pages,
                  :thumbnail, :language, :artist, :tags, :group, :parody, 
                  :category, :scanlator, :id, :num_pages
  end

  class Title
    attr_accessor :english, :japanese
  end

  class Picture
    attr_accessor :height, :width, :type, :url
  end

end
