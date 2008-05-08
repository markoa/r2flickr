require 'flickr/base'

class Flickr::Licenses < Flickr::APIBase
	def getInfo
		return @flickr.license_cache_lookup if
			@flickr.license_cache_lookup
		list = {}
		res = @flickr.call_method('flickr.photos.licenses.getInfo')
		res.elements['/licenses'].each_element do |el|
			lic = Flickr::License.from_xml(el)
			list[lic.id] = lic
		end
		@flickr.license_cache_store(list)
		return list
	end
	
	def setLicense(photo,license)
		photo = photo.id if photo.class == Flickr::Photo
		license = license.id if license.class == Flickr::License
		@flickr.call_method('flickr.photos.licenses.setLicense',
			'photo_id' => photo, 'license_id' => license)
	end
end
