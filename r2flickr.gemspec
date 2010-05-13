Gem::Specification.new do |spec|
	spec.author = 'Marko Anastasov'
	spec.email = 'marko.anastasov@gmail.com'
	spec.date = '2010-05-13'
	spec.version = '0.2'
	spec.name = 'r2flickr'
	spec.has_rdoc = false
	spec.homepage = 'http://github.com/markoa/r2flickr/'

	spec.files=%w(
		LICENSE
		README.textile
		lib/flickr/auth.rb
		lib/flickr/base.rb
		lib/flickr/blogs.rb
                lib/flickr/comments.rb
		lib/flickr/contacts.rb
		lib/flickr/favorites.rb
		lib/flickr/groups.rb
		lib/flickr/interestingness.rb
		lib/flickr/licenses.rb
		lib/flickr/notes.rb
		lib/flickr/people.rb
		lib/flickr/photos.rb
		lib/flickr/photosets.rb
		lib/flickr/pools.rb
		lib/flickr/reflection.rb
		lib/flickr/tags.rb
		lib/flickr/test.rb
		lib/flickr/token_cache.rb
		lib/flickr/transform.rb
		lib/flickr/upload.rb
		lib/flickr/urls.rb
		lib/flickr.rb
		examples/album_test.rb
		examples/comics-reorder.rb
		examples/loadr.rb
		examples/relatedness.rb
                examples/search.rb
		examples/setdumpr.rb)

	spec.summary = 'r2flickr is a ruby interface to the Flickr API'
	spec.description =<<EOM
r2flickr is a fork of rflickr, a Ruby implementation of the Flickr API.
It includes a faithful reproduction of the published API as well as
method encapsulation to provide more useful object mappings.
rflickr features result caching to improve performance.
EOM
end
