require 'rubygems'
require 'rake'

spec = Gem::Specification.new
spec.autorequire = 'rake'
spec.email = 'marko.anastasov@gmail.com'
spec.date = '2008.05.08'
spec.version = '0.1'
spec.name = 'r2flickr'
spec.has_rdoc = false
spec.homepage = 'http://github.com/markoa/r2flickr/'
spec.files = FileList['lib/**/*.rb', 'lib/flickr/*.rb',
             'sample/*.rb', 'LICENCE', 'README'].to_a
spec.summary = 'r2flickr is a ruby interface to the Flickr API'
spec.description =<<EOM
r2flickr is a fork of rflickr, a Ruby implementation of the Flickr API.
It includes a faithful reproduction of the published API as well as
method encapsulation to provide more useful object mappings.
rflickr features result caching to improve performance.
EOM
