require 'flickr/base'

class Flickr::Urls < Flickr::APIBase
	def getGroup(group)
		group = group.nsid if group.class == Flickr::Group
		res = @flickr.call_method('flickr.urls.getGroup',
			'group_id' => group)
		return res.elements['/group'].attributes['url']
	end

	def getUserPhotos(user)
		user = user.nsid if user.respond_to?(:nsid)
		args = {}
		args['user_id'] = user if user
		res = @flickr.call_method('flickr.urls.getUserPhotos',args)
		return res.elements['/user'].attributes['url']
	end

	def getUserProfile(user)
		user = user.nsid if user.respond_to?(:nsid)
		args = {}
		args['user_id'] = user if user
		res = @flickr.call_method('flickr.urls.getUserProfile',args)
		return res.elements['/user'].attributes['url']
	end

	def lookupGroup(url)
		res = @flickr.call_method('flickr.urls.lookupGroup','url'=>url)
		els = res.elements
		nsid = els['/group'].attributes['id']

		g = @flickr.group_cache_lookup(nsid) ||
			Flickr::Group.new(@flickr,nsid,
					els['/group/groupname'].text)
		@flickr.group_cache_store(g)
		return g
	end

	def lookupUser(url)
		res = @flickr.call_method('flickr.urls.lookupUser','url'=>url)
		els = res.elements
		nsid = els['/user'].attributes['id']
		p = @flickr.person_cache_lookup(nsid) ||
			Flickr::Person.new(@flickr,nsid,
				els['/user/username'].text)
		@flickr.person_cache_store(p)
		return p
	end
end
