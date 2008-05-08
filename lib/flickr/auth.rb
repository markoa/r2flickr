#!/usr/bin/env ruby

require 'flickr/base'

class Flickr::Auth < Flickr::APIBase
	attr_accessor :cache_file, :token

	def clear_cache
		@token = nil
		@frob = nil
	end

	def initialize(flickr,cache_file=nil)
		super(flickr)
		@frob = nil
		@token = nil
		@cache_file = cache_file
		if @cache_file && File.exists?(@cache_file)
			load_token
		end
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

	def cache_token
		File.open(@cache_file,'w'){ |f| f.write @token.to_xml } if token
	end

	def load_token
		token = nil
		File.open(@cache_file,'r'){ |f| token = f.read }
		# Dirt stupid check to see if it's probably XML or
		# not.  If it is, then we don't call checkToken.
		#
		# Backwwards compatible with old token storage.
		@token = token.include?('<') ?
			Flickr::Token.from_xml(REXML::Document.new(token)) :
			@token = checkToken(token)
	end

	def getToken(frob=nil)
		frob ||= @frob
		res=@flickr.call_unauth_method('flickr.auth.getToken',
				'frob'=>frob)
		@token = Flickr::Token.from_xml(res)
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

	def checkToken(token=nil)
		token ||= @token
		token = token.token if token.class == Flickr::Token
		res = @flickr.call_unauth_method('flickr.auth.checkToken',
			'auth_token' => token)
		@token = Flickr::Token.from_xml(res)
	end
end
