require 'flickr/groups'

class Flickr::Pools < Flickr::APIBase
	def initialize(flickr,groups)
		super(flickr)
		@groups = groups
	end

	# photo can be a Photo or photo_id
	# group can be a Group or group_id
	def add(photo,group)
		group = group.nsid if group.class == Flickr::Group
		photo = photo.id if photo.class == Flickr::Photo
		@flickr.call_method('flickr.groups.pools.add',
			'group_id' => group, 'photo_id' => photo)
	end

	# photo can be a Photo or photo_id
	# group can be a Group or group_id
	def remove(photo,group)
		group = group.nsid if group.class == Flickr::Group
		photo = photo.id if photo.class == Flickr::Photo
		@flickr.call_method('flickr.groups.pools.add',
			'group_id' => group, 'photo_id' => photo)
	end

	# photo can be a Photo or photo_id
	# group can be a Group or group_id
	def getContext(photo,group)
		group = group.nsid if group.class == Flickr::Group
		photo = photo.id if photo.class == Flickr::Photo
		res = @flickr.call_method('flickr.groups.pools.getContex',
			'group_id' => group, 'photo_id' => photo)
		return Flickr::Context.from_xml(res)
	end

	def getGroups
		res = @flickr.call_method('flickr.groups.pools.getGroups')
		list = []
		res.elements['/groups'].each_element do |el|
			att = el.attributes
			nsid = att['nsid']
			g = @flickr.group_cache_lookup(nsid) ||
				Flickr::Group.new(@flickr,nsid,att['name'])
			g.name = att['name']
			g.admin = att['admin'].to_i == 1
			g.privacy = Flickr::Group::PRIVACY[att['privacy'].to_i]
			g.photo_count = att['photos'].to_i
			g.iconserver = att['iconserver'].to_i

			@flickr.group_cache_store(g)
			list << g
		end
		return list
	end

	def getPhotos(group,tags=nil,extras=nil,per_page=nil,page=nil)
		group = group.nsid if group.class == Flickr::Group
		group = group.id.to_s if group.class == Flickr::PhotoPool
		args = { 'group_id' => group }
		args['tags'] = tags.map{|t| t.clean if t.class ==
			Flick::Tag}.join(',') if tags
		args['extras'] = extras.join(',') if extras.class == Array
		args['per_page'] = per_page if per_page
		args['page'] = page if page

		res = @flickr.call_method('flickr.groups.pools.getPhotos', args)
		return Flickr::PhotoList.from_xml(res,@flickr)
	end
end
