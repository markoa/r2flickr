require 'flickr/base'

class Flickr::PhotoSets < Flickr::APIBase
	# photoset can be a PhotoSet or a a photoset id
	# photo can be a Photo or a photo id
	def addPhoto(photoset,photo)
		photo = photo.id if photo.class == Flickr::Photo
		photoset = photoset.id if photoset.class == Flickr::PhotoSet

		@flickr.call_method('flickr.photosets.addPhoto',
			'photoset_id' => photoset, 'photo_id' => photo)
	end

	def create(title,primary_photo, description = nil)
		primary_photo = primary_photo.id if
			primary_photo.class == Flickr::Photo
		args = { 'title' => title, 'primary_photo_id' =>
			primary_photo}
		args['description'] = description if description
		res = @flickr.call_method('flickr.photosets.create',args)
		id = res.elements['/photoset'].attributes['id']
		url = res.elements['/photoset'].attributes['url']
		set = Flickr::PhotoSet.new(id,@flickr)
		set.title = title
		set.url = url
		@flickr.photoset_cache_store(set)
		return set
	end

	def delete(photoset)
		photoset = photoset.id if photoset.class == Flickr::PhotoSet
		@flickr.call_method('flickr.photosets.delete',
			'photoset_id' => photoset)
	end

	def editMeta(photoset,title,description=nil)
		photoset = photoset.id if photoset.class == Flickr::PhotoSet
		args = {'photoset_id' => photoset,
			'title' => title}
		args['description' ] = description if description
		@flickr.call_method('flickr.photosets.editMeta',args)
	end

	def editPhotos(photoset,primary_photo,photos)
		photoset = photoset.id if photoset.class == Flickr::PhotoSet
		primary_photo = primary_photo.id if
			primary_photo.class == Flickr::Photo
		photos=photos.map{|p| p.id if p.class==Flickr::Photo}.join(',')
		args = {'photoset_id' => photoset,
			'primary_photo_id' => primary_photo,
			'photo_ids' => photos }
		@flickr.call_method('flickr.photosets.editPhotos',args)
	end

	def getContext(photo,photoset)
		photoset = photoset.id if photoset.class == Flickr::PhotoSet
		photo = photo.id if photo.class == Flickr::Photo
		res = @flickr.call_method('flickr.photosets.getContext',
			'photo_id' => photo, 'photoset_id' => photoset)
		return Flickr::Context.from_xml(res,@flickr)
	end

	def getList(user=nil)
		user = user.nsid if user.respond_to?(:nsid)
		args = {}
		args['user_id'] = user if user
		res = @flickr.call_method('flickr.photosets.getList',args)
		list = []
		res.elements['/photosets'].each_element do |el|
			list << Flickr::PhotoSet.from_xml(el,@flickr)
		end
		return list
	end

	def removePhoto(photoset,photo)
		photoset = photoset.id if photoset.class == Flickr::PhotoSet
		photo = photo.id if photo.class == Flickr::Photo
		@flickr.call_method('flickr.photosets.removePhoto',
			'photo_id' => photo, 'photoset_id' => photoset)
	end

	def getPhotos(photoset,extras=nil)
		photoset = photoset.id if photoset.class == Flickr::PhotoSet
		extras = extras.join(',') if extras.class == Array
		args = { 'photoset_id' => photoset }
		args['extras'] = extras if extras
		res = @flickr.call_method('flickr.photosets.getPhotos',args)
		return Flickr::PhotoSet.from_xml(res.root,@flickr)
	end

	def getInfo(photoset)
		photoset = photoset.id if photoset.class == Flickr::PhotoSet
		res = @flickr.call_method('flickr.photosets.getInfo',
			'photoset_id' => photoset)
		return Flickr::PhotoSet.from_xml(res.root,@flickr)
	end

	def orderSets(photosets)
		photosets=photosets.map { |ps|
			(ps.class==Flickr::PhotoSet) ? ps.id : ps}.join(',')
		@flickr.call_method('flickr.photosets.orderSets',
				'photoset_ids' => photosets)
	end
end
