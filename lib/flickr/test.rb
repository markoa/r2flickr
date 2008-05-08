require 'flickr/base'

class Flickr::Test < Flickr::APIBase
	# This has to be a Hash
	def echo(args)
		return @flickr.call_method('flickr.test.echo',args)
	end

	def login
		res = @flickr.call_method('flickr.test.login')
		nsid = res.elements['/user'].attributes['id']
		name = res.elements['/user/username'].text
		p = @flickr.person_cache_lookup(nsid) ||
			Flickr::Person.new(@flickr,nsid,name)
		p.name = name
		@flickr.person_cache_store(p)
		return p
	end
end
