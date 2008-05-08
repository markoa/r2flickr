require 'flickr/base'

class Flickr::Photos < Flickr::APIBase
	def upload
	require 'flickr/upload'
		@upload ||= Flickr::Upload.new(@flickr)
	end

	def licenses
	require 'flickr/licenses'
		@licenses ||= Flickr::Licenses.new(@flickr)
	end

	def notes
	require 'flickr/notes'
		@notes ||= Flickr::Notes.new(@flickr)
	end

	def transform
	require 'flickr/transform'
		@transform ||= Flickr::Transform.new(@flickr)
	end

	# photo can be a Photo or a photo id
	# tags is an array of tags
	def addTags(photo,tags)
		photo = photo.id if photo.class == Flickr::Photo
		tstr = tags.join(',')
		@flickr.call_method('flickr.photos.addTags',
			'photo' => photo, 'tags' => tstr)
	end

	def removeTag(tag)
		tag = tag.id if tag.class == Flickr::Tag
		@flickr.call_method('flickr.photos.removeTag', 'tag_id' => tag)
	end

	def setTags(tags)
		tags=tags.map{|t| (t.class == Flickr::Tag) ? t.id : t}.join(' ')
		photo = photo.id if photo.class == Flickr::Photo
		@flickr.call_method('flickr.photos.setTags',
			'photo_id' => photo, 'tags' => tags)
	end

	# photo can be a Photo or photo id string/number
	def delete(photo)
		photo = photo.id if photo.class == Flickr::Photo
		res = @flickr.call_method('flickr.photos.delete',
		    'photo_id'=>photo)
	end

	# photo can be a Photo or photo id string/number
	def getAllContexts(photo)
		photo = photo.id if photo.class == Flickr::Photo
		res @flickr.call_method('flickr.photos.getAllContexts',
		    'photo_id'=>photo)
		list = []
		res.each_element('set') do |set|
			att = set.attributes
			psid = att['id']
			set = @flickr.photoset_cache_lookup(psid) ||
				Flickr::PhotoSet.new(att['id'],@flickr)
			set.title = att['title']

			@flickr.photoset_cache_store(set)
			list << set
		end
		res.each_element('pool') do |set|
			att = set.attributes
			ppid = att['id']

			p = @flickr.photopool_cache_lookup(ppid) ||
				Flickr::PhotoPool.new(ppid,@flickr)
			p.title = att['title']
			@flickr.photopool_cache_store(ppid)
			list << p
		end
		return list
	end

	def getPerms(photo)
		photo = photo.id if photo.class == Flickr::Photo
		res = @flickr.call_method('flickr.photos.getPerms',
			'photo_id' => photo)
		perms = res.elements['/perms']
		att = perms.attributes
		phid = att['id']
		photo = (photo.class == Flickr::Photo) ? photo :
			(@flickr.photo_cache_lookup(phid) ||
			 	Flickr::Photo.new(@flickr,phid))
		photo.ispublic = (att['ispublic'].to_i == 1)
		photo.isfriend = (att['isfriend'].to_i == 1)
		photo.isfamily = (att['isfamily'].to_i == 1)
		photo.permcomment = att['permcomment'].to_i 
		photo.permaddmeta = att['permaddmeta'].to_i
		return photo
	end

	def setPerms(photo,is_public,is_friend,is_family,perm_comment,
			perm_addmeta)
		photo = photo.id if photo.class == Flickr::Photo
		args = {
		'photo_id' => photo,
		'is_public' => (is_public == true || is_public == 1) ? 1 : 0,
		'is_friend' => (is_friend == true || is_friend == 1) ? 1 : 0,
		'is_family' => (is_family == true || is_family == 1) ? 1 : 0,
		'perm_comment' => perm_comment,
		'perm_addmeta' => perm_addmeta
		}
		res = @flickr.call_method('flickr.photos.setPerms',args)
	end

	def getContactsPhotos(count=nil,just_friends=nil,single_photo=nil,
			include_self=nil)
		args = {}
		args['count'] = count if count
		args['just_friends'] = just_friends ? '1' : '0' if
			just_friends != nil
		args['single_photo'] = single_photo ? '1' : '0' if
			single_photo != nil
		args['include_self'] = include_self ? '1' : '0' if
			include_self != nil
		res= @flickr.call_method('flickr.photos.getContactsPhotos',args)
		return Flickr::PhotoList.from_xml(res,@flickr)
	end

	# Person can be a string nsid or anything that responds to the
	# nsid method.
	def getContactsPublicPhotos(user, count=nil,just_friends=nil,
			single_photo=nil, include_self=nil)
		user = user.nsid if user.respond_to?(:nsid)
		args = {}
		args['count'] = count if count
		args['user_id'] = user
		args['just_friends'] = just_friends ? '1' : '0' if
			just_friends != nil
		args['single_photo'] = single_photo ? '1' : '0' if
			single_photo != nil
		args['include_self'] = include_self ? '1' : '0' if
			include_self != nil
		res=@flickr.call_method('flickr.photos.getContactsPublicPhotos',
		                        args)
		 return Flickr::PhotoList.from_xml(res,@flickr)
	end

	def getContext(photo)
		photo = photo.id if photo.class == Flickr::Photo
		res = @flickr.call_method('flickr.photos.getContext',
			'photo_id' => photo)
		return Flickr::Context.from_xml(res)
	end

	def getCounts(dates=nil,taken_dates=nil)
		args = {}
		args['dates'] = dates.map{|d| d.to_i}.join(',') if dates
		args['taken_dates'] = taken_dates.map{|d| d.to_i}.join(',') if
			taken_dates
		res = @flickr.call_method('flickr.photos.getCounts',args)
		list = []
		res.elements['/photocounts'].each_element('photocount') do |el|
			list << Flickr::Count.from_xml(el)
		end
		return list
	end

	def getExif(photo,secret = nil)
		photo = photo.id if photo.class == Flickr::Photo
		args = {'photo_id' => photo}
		args['secret'] = secret if secret
		res = @flickr.call_method('flickr.photos.getExif',args)
		return Flickr::Photo.from_xml(res.elements['/photo'],@flickr)
	end

	def getInfo(photo,secret = nil)
		photo = (photo.class == Flickr::Photo) ? photo.id : photo
		args= {'photo_id' => photo}
		args['secret'] = secret if secret
		res = @flickr.call_method('flickr.photos.getInfo',args)
		return Flickr::Photo.from_xml(res.elements['photo'],@flickr)
	end
	
	def getNotInSet(extras=nil,per_page = nil, page = nil)
		args = {}
		extras = extras.join(',') if extras.class == Array
		args['extras'] = extras if extras
		args['per_page'] = per_page if per_page
		args['page'] = page if page
		res = @flickr.call_method('flickr.photos.getNotInSet',args)
		return Flickr::PhotoList.from_xml(res,@flickr)
	end
	
	def getRecent(extras=nil,per_page = nil, page = nil)
		args = {}
		extras = extras.join(',') if extras.class == Array
		args['extras'] = extras if extras
		args['per_page'] = per_page if per_page
		args['page'] = page if page
		res = @flickr.call_method('flickr.photos.getRecent',args)
		return Flickr::PhotoList.from_xml(res,@flickr)
	end
	
	def getUntagged(extras=nil,per_page = nil, page = nil)
		args = {}
		extras = extras.join(',') if extras.class == Array
		args['extras'] = extras if extras
		args['per_page'] = per_page if per_page
		args['page'] = page if page
		res = @flickr.call_method('flickr.photos.getUntagged',args)
		return Flickr::PhotoList.from_xml(res,@flickr)
	end

	def getSizes(photo)
		photo_id = (photo.class == Flickr::Photo) ? photo.id : photo
		photo = (photo.class == Flickr::Photo) ? photo :
			(@flickr.photo_cache_lookup(photo_id) ||
			 	Flickr::Photo.new(@flickr,photo_id))
		res = @flickr.call_method('flickr.photos.getSizes',
			'photo_id' => photo_id )
		photo.sizes = {}
		res.elements['/sizes'].each_element do |el|
			size = Flickr::Size.from_xml(el)
			photo.sizes[size.label.intern] = size
		end
		@flickr.photo_cache_store(photo)
		return photo
	end

	def setDates(photo,date_posted=nil,date_taken=nil,
			date_taken_granularity=nil)
		photo = photo.id if photo.class == Flickr::Photo
		date_posted = date_posted.to_i if date_posted.class == Time
		date_taken = @flickr.mysql_datetime(date_taken) if
			date_taken.class == Time
		args = {'photo_id' => photo}
		args['date_posted'] = date_posted if date_posted
		args['date_taken'] = date_taken if date_taken
		args['date_taken_granularity'] = date_taken_granularity if
			date_taken_granularity
		@flickr.call_method('flickr.photos.setDates',args)
	end

	def setMeta(photo,title,description)
		photo = photo.id if photo.class == Flickr::Photo
		args = {'photo_id' => photo,
			'title' => title,
			'description' => description}
		@flickr.call_method('flickr.photos.setMeta',args)
	end

	def search(user=nil,tags=nil,tag_mode=nil,text=nil,min_upload_date=nil,
		max_upload_date=nil,min_taken_date=nil,max_taken_date=nil,
		license=nil,extras=nil,per_page=nil,page=nil,sort=nil)
	
		user = user.nsid if user.respond_to?(:nsid)
		tags = tags.join(',') if tags.class == Array
		min_upload_date = min_upload_date.to_i if
			min_upload_date.class == Time
		max_upload_date = max_upload_date.to_i if
			max_upload_date.class == Time
		min_taken_date = @flickr.mysql_datetime(min_taken_date) if
			min_taken_date.class == Time
		max_taken_date = @flickr.mysql_datetime(max_taken_date) if
			max_taken_date.class == Time
		license = license.id if license.class == Flickr::License
		extras = extras.join(',') if extras.class == Array

		args = {}
		args['user_id'] = user if user
		args['tags'] = tags if tags
		args['tag_mode'] = tag_mode if tag_mode
		args['text'] = text if text
		args['min_upload_date'] = min_upload_date if min_upload_date
		args['max_upload_date'] = max_upload_date if max_upload_date
		args['min_taken_date'] = min_taken_date if min_taken_date
		args['max_taken_date'] = max_taken_date if max_taken_date
		args['license'] = license if license
		args['extras'] = extras if extras
		args['per_page'] = per_page if per_page
		args['page'] = page if page
		args['sort'] = sort if sort

		res = @flickr.call_method('flickr.photos.search',args)
		return Flickr::PhotoList.from_xml(res,@flickr)
	end
end
