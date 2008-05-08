require 'flickr/base'

class Flickr::Blogs < Flickr::APIBase

	def getList()
		return @flickr.blog_cache_lookup if @flickr.blog_cache_lookup
		res = @flickr.call_method('flickr.blogs.getList')
		list = []
		res.elements['/blogs'].each_element do |e|
			att = e.attributes
			list << Flickr::Blog.new(att['id'], att['name'],
				att['needspassword'].to_i == 1, att['url'])
		end
		@flickr.blog_cache_store(list)
		return list
	end

	# blog can be either an integer blog ID or a Blog object
	# photo can be either an integer photo ID or a Photo object
	def postPhoto(blog, photo, title, description, blog_password=nil)
		blog = blog.id if blog.class == Flickr::Blog
		photo = photo.id if photo.class == Flickr::Photo

		args={'blog'=>blog,'photo'=>photo,'title'=>title,
			description=>'description'}
		args['blogs_password'] = blog_password if blog_password

		@flickr.call_method('flickr.blogs.postPhoto',args)
	end
end
