require 'rubygems'
require 'rake'

spec = Gem::Specification.new
spec.autorequire='rake'
spec.email = 'marko.anastasov@gmail.com'
spec.version = '2008.05.08'
spec.name = 'r2flickr'
spec.has_rdoc = false
spec.homepage = 'http://rubyforge.org/projects/rflickr/'
spec.rubyforge_project = 'rflickr'
spec.files = FileList['LICENCE', 'README', 'lib/**/*.rb', 'lib/flickr/*.rb',
             'sample/*.rb''].to_a
spec.add_dependency('mime-types')
spec.summary = 'Ruby interface to the Flickr API'
spec.description =<<EOM
r2flickr is a Ruby implementation of the Flickr API. It includes a
faithful reproduction of the published API as well as method
encapsulation to provide more useful object mappings. r2flickr features
result caching to improve performance.
EOM
