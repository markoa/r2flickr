#!/usr/bin/env ruby

require 'flickr/base'
require 'flickr/token_cache'

class Flickr::Auth < Flickr::APIBase
	attr_accessor :token_cache, :token

	def clear_cache
		@token = nil
		@frob = nil
	end

	def initialize(flickr, token_cache=nil)
		super(flickr)
		@frob = nil
		@token = nil
		@token_cache = case token_cache
		when String
			Flickr::FileTokenCache.new token_cache
		else
			token_cache
		end
		@token = @token_cache.load_token if @token_cache
	end

	def login_link(perms='delete')
		args={ 'api_key' => @flickr.api_key, 'perms' => perms}
		args['frob'] = self.frob
		args['api_sig'] = @flickr.sign(args)
		return "http://flickr.com/services/auth/?"+
			args.to_a.map{|arr| arr.join('=')}.join('&')
	end

	def frob=(frob) @frob = frob end
	def frob() return @frob || getFrob end

	def getToken(frob=nil)
		frob ||= @frob
		res=@flickr.call_unauth_method('flickr.auth.getToken',
				'frob'=>frob)
		@token = Flickr::Token.from_xml(res)
	end

	def cache_token
		@token_cache.cache_token(@token) if @token_cache
	end

	def getFullToken(mini_token)
		res = flickr.call_unauth_method('flickr.auth.getFullToken',
				'mini_token' => mini_token)
		@token = Flickr::Token.from_xml(res)
	end

	def getFrob
		doc = @flickr.call_unauth_method('flickr.auth.getFrob')
		@frob = doc.elements['/frob'].text
		return @frob
	end

end
