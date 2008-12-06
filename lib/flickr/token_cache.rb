require 'flickr/base'

class Flickr::BaseTokenCache < Flickr::APIBase

  def load_token
    nil
  end

  def cache_token(token)
    nil
  end

end

class Flickr::FileTokenCache < Flickr::BaseTokenCache

  def initialize(filename)
    @cache_file = filename
  end

  def load_token
    token = nil
    File.open(@cache_file,'r'){ |f| token = f.read }
    @token = Flickr::Token.from_xml(REXML::Document.new(token))
  rescue Errno::ENOENT
    nil
  end

  def cache_token(token)
    File.open(@cache_file,'w'){ |f| f.write token.to_xml } if token
  end

end
