require 'flickr/base'

class Flickr::People < Flickr::APIBase
	def findByEmail(find_email)
		res = @flickr.call_method('flickr.people.findByEmail',
			'find_email' => find_email)
		p = Flickr::Person.from_xml(res,@flickr)
		return p
	end

	def findByUsername(username)
		res = @flickr.call_method('flickr.people.findByUsername',
			'username' => username)
		p = Flickr::Person.from_xml(res,@flickr)
		return p
	end

	# user can be a Person or an nsid
	def getInfo(user)
		user = user.nsid if user.class == Flickr::Person
		res = @flickr.call_method('flickr.people.getInfo',
				'user_id'=>user)
		person = Flickr::Person.from_xml(res,@flickr)
		return person
	end

	# user can be a Person or an nsid
	def getPublicGroups(user)
	require 'flickr/groups'
		groups = @flickr.groups
		user = user.nsid if user.class == Flickr::Person
		res = @flickr.call_method('flickr.people.getPublicGroups',
			'user_id' => user)
		list = []
		res.elements['/groups'].each_element('group') do |e|
			att = e.attributes
			nsid = att['nsid']

			g = @flickr.group_cache_lookup(nsid) ||
				Flickr::Group.new(@flickr,nsid)

			g.name = att['name']
			g.eighteenplus = att['eighteenplus'].to_i == 1

			@flickr.group_cache_store(g)
			list << g
		end
		return list
	end

	def getPublicPhotos(user,extras=nil,per_page=nil,page=nil)
		args = {}

		user = user.nsid if user.class == Flickr::Person

		args['user_id'] = user if user
		args['extras'] = extras.join(',') if extras.class == Array
		args['per_page'] = per_page if per_page
		args['page'] = page if page

		res = @flickr.call_method('flickr.people.getPublicPhotos',args)
		att = res.root.attributes
		list = Flickr::PhotoList.new(att['page'].to_i,att['pages'].to_i,
			att['perpage'].to_i,att['total'].to_i)
		res.elements['/photos'].each_element do |e|
			list << Flickr::Photo.from_xml(e,@flickr)
		end
		return list
	end

	# user can be a Person or an nsid
	def getUploadStatus(user)
		user = user.nsid if user.class == Flickr::Person
		res = @flickr.call_method('flickr.people.getUploadStatus',
				'user_id'=>user)
		person = Flickr::Person.from_xml(res,@flickr)
		return person
	end
end
