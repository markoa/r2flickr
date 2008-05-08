#!/usr/bin/env ruby

## Structure this class hierarchy the way the Flickr API is structured.
## Flickr::Auth and so on.  At least think about whether it makes sense or
## not.

require 'xmlrpc/client'
require 'md5'
require 'rexml/document'
require 'parsedate'

class Flickr
	API_KEY=''
	SHARED_SECRET=''

	attr_reader :api_key
	attr_accessor :async, :debug, :caching, :auth_mode

############################### CACHE ACCESSORS ###########################
	def ticket_cache_lookup(id) @ticket_by_id[id] if @caching end

	def ticket_cache_store(ticket)
		@ticket_by_id[ticket.id] = ticket if @caching
	end

	def person_cache_lookup(nsid) @person_by_nsid[nsid] if @caching end

	def person_cache_store(person)
		@person_by_nsid[person.nsid] = person if @caching
	end

	def photo_cache_lookup(id) @photo_by_id[id] if @caching end

	def photo_cache_store(photo)
		@photo_by_id[photo.id] = photo if @caching
	end

	def license_cache_lookup() @license_cache if @caching end

	def license_cache_store(licenses)
		@license_cache = licenses if @caching
	end

	def blog_cache_lookup() @blog_cache if @caching end

	def blog_cache_store(blogs) @blog_cache = blogs if @caching end

	def photoset_cache_lookup(id) @photoset_by_id[id] if @caching end

	def photoset_cache_store(set)
		@photoset_by_id[set.id] = set if @caching
	end

	def photopool_cache_lookup(id) @photopool_by_id[id] if @caching end

	def photopool_cache_store(pool)
		@photopool_by_id[pool.id] = pool if @caching
	end

	def group_cache_lookup(id) @group_by_id[id] if @caching end

	def group_cache_store(group)
		@group_by_id[group.id] = group if @caching
	end
############################################################################

	def debug(*args) $stderr.puts(sprintf(*args)) if @debug end

	def Flickr.todo
		[
	  'Refactor, especially more Class.from_xml methods',
	  'More logical OO design, wrap the API methods to make transparent',
	  'Class & method documentation',
	  'Unit tests',
	  'Implement missing methods (see flickr.reflection.missing_methods)'
	  	]
	end
	def todo()
		Flickr.todo+reflection.missing_methods.map{|m| 'Implement '+m}
	end

	
	def initialize(token_cache=nil,api_key=API_KEY,
			shared_secret=SHARED_SECRET,
			endpoint='http://www.flickr.com/services/xmlrpc/')
		@async = false
		@caching = true
		@auth_mode = true
		@api_key=api_key
		@shared_secret=shared_secret
		@token_cache = token_cache
		@endpoint=endpoint
		proto,host,port,path,user,pass=parse_url(@endpoint)
		raise ProtoUnknownError.new("Unhandled protocol '#{proto}'") if
			proto.downcase != 'http'
		@client=XMLRPC::Client.new(host,path,port)
		clear_cache
	end

	def clear_cache()
		@auth = nil
		@blogs = nil
		@contacts = nil
		@favorites = nil
		@groups = nil
		@interestingness = nil
		@reflection = nil
		@people = nil
		@photos = nil
		@photosets = nil
		@test = nil
		@urls = nil

		@ticket_by_id = {}
		@person_by_nsid = {}
		@photo_by_id = {}
		@photoset_by_id = {}
		@photopool_by_id = {}
		@group_by_id = {}
		@license_cache = nil
		@blog_cache = nil
	end

	def auth() @auth ||= Auth.new(self,@token_cache) end
	def blogs() @blogs ||= Blogs.new(self) end
	def contacts() @contacts ||= Contacts.new(self) end
	def favorites() @favorites ||= Favorites.new(self) end
	def groups() @groups ||= Groups.new(self) end
	def people() @people ||= People.new(self) end
	def photos() @photos ||= Photos.new(self) end
	def photosets() @photosets ||= PhotoSets.new(self) end
	def reflection() @reflection ||= Reflection.new(self) end
	def test() @test ||= Test.new(self) end
	def urls() @urls ||= Urls.new(self) end
	def tags() @tags ||= Tags.new(self) end
	def interestingness() @interestingness ||= Interestingness.new(self) end

	def call_method(method,args={})
		@auth_mode ? call_auth_method(method,args) :
		             call_unauth_method(method,args)
	end

	def call_unauth_method(method,args={})
		debug('%s(%s)', method, args.inspect)
		tries = 3
		args = args.dup
		args['api_key'] = @api_key
		api_sig=sign(args)
		args['api_sig']=api_sig
		begin
			tries -= 1;
			str = @async ? @client.call_async(method,args) :
				@client.call(method,args)
			debug('RETURN: %s',str)
			return REXML::Document.new(str)
		rescue Timeout::Error => te
			$stderr.puts "Timed out, will try #{tries} more times."
			if tries > 0
				retry
			else
				raise te
			end
		rescue REXML::ParseException => pe
			return REXML::Document.new('<rsp>'+str+'</rsp>').
				elements['/rsp']
		rescue XMLRPC::FaultException => fe
			$stderr.puts "ERR: #{fe.faultString} (#{fe.faultCode})"
			raise fe
		end
	end

	def call_auth_method(method,args={})
		at = args['auth_token']
		args['auth_token'] ||= auth.token.token
		res = call_unauth_method(method,args)
		args.delete('auth_token') unless at
		return res
	end

	def sign(args)
		return MD5.md5(@shared_secret+args.sort.flatten.join).to_s
	end

	def parse_url(url)
		url =~ /([^:]+):\/\/([^\/]*)(.*)/
		proto = $1.to_s
		hostplus = $2.to_s
		path = $3.to_s

		hostplus =~ /(?:(.*)@)?(.*)/
		userpass = $1
		hostport = $2
		user,pass = userpass.to_s.split(':',2)
		host,port = hostport.to_s.split(':',2)
		port = port ? port.to_i : 80

		return proto,host,port,path,user,pass
	end

	def mysql_datetime(time) time.strftime('%Y-%m-%d %H:%M:%S') end
	def mysql_date(time) time.strftime('%Y-%m-%d') end
end

class Flickr::APIBase
	attr_reader :flickr

	def initialize(flickr) @flickr = flickr end
end

class Flickr::Token
	attr_reader :token, :perms, :user

	def initialize(token, perms, user)
		@token = token
		@perms = perms
		@user = user
	end

	def self.from_xml(xml, flickr=nil)
		token = xml.elements['/auth/token'].text
		perms = xml.elements['/auth/perms'].text.intern
		user = xml.elements['/auth/user']
		nsid = user.attributes['nsid']
		username = user.attributes['username']
		fullname = user.attributes['fullname']

		p = flickr.person_cache_lookup(nsid) if flickr
		p ||= Flickr::Person.new(flickr,nsid,username)
		p.realname=fullname
		flickr.person_cache_store(p) if flickr

		return Flickr::Token.new(token,perms,p)
	end

	def to_xml
		    return "<auth><token>#{self.token}</token>"+
		           "<perms>#{self.perms}</perms>"+
			   "<user nsid=\"#{self.user.nsid}\" "+
			   "username=\"#{self.user.username}\" "+
			   "fullname=\"#{self.user.realname}\" /></auth>"
	end
end

class Flickr::Blog
	attr_reader :id, :name, :needspassword, :url

	def initialize(id,name,needspassword,url)
		@id = id
		@name = name
		@needspassword = needspassword
		@url = url
	end
end

class Flickr::Person
	attr_accessor :nsid, :username, :realname, :mbox_sha1sum, :location,
	:photosurl, :profileurl, :photos_firstdate, :photos_firstdatetaken,
	:photos_count, :info_fetched, :isadmin, :ispro, :iconserver,
	:bandwidth_max, :bandwidth_used, :filesize_max, :upload_fetched,
	:friend, :family, :ignored

	def initialize(flickr, nsid, username)
		@flickr = flickr
		@nsid = nsid
		@username = username
		@info_fetched = false
		@upload_fetched = false
	end

	def full_info()
		self.info_fetched ? self : @flickr.people.getInfo(self)
	end
	def upload_status() self.upload_fetched ? self :
		@flickr.people.getUploadStatus(self) end
		

	# I think this will define a class method.  You can't use
	# Flickr::Person.from_xml and if you just say Person.from_xml, it
	# can't resolve Flickr::Person::Person
	def self.from_xml(xml,flickr=nil)
		els = xml.elements
		att = xml.root.attributes

		nsid = cond_attr(att,'nsid')
		username = cond_text(els,'/person/username')

		p = flickr.person_cache_lookup(nsid) if flickr
		p ||= Flickr::Person.new(flickr,nsid,username)
		
		p.username = username
		p.isadmin = cond_attr(att,'isadmin') &&
			cond_attr(att,'isadmin') == '1'
		p.ispro = cond_attr(att,'ispro') &&
			cond_attr(att,'ispro') == '1'
		p.iconserver = cond_attr(att,'iconserver') &&
			cond_attr(att,'iconserver').to_i
		p.realname = cond_text(els,'/person/realname')
		p.mbox_sha1sum = cond_text(els,'/person/mbox_sha1sum')
		p.location = cond_text(els,'/person/location')
		p.photosurl = cond_text(els,'/person/photosurl')
		p.profileurl = cond_text(els,'/person/profileurl')
		tstr = cond_text(els,'/person/photos/firstdate')
		p.photos_firstdate = Time.at(tstr.to_i) if tstr
		tstr = cond_text(els, '/person/photos/firstdatetaken')
		p.photos_firstdatetaken = Time.gm(*ParseDate.parsedate(tstr)) if
			tstr
		p.photos_count = cond_text(els,'/person/photos/count')
		p.photos_count = p.photos_count if p.photos_count

		p.info_fetched = true if p.photos_count

		if els['/user/bandwidth']
			att = els['/user/bandwidth'].attributes
			p.bandwidth_max = cond_attr(att,'max') &&
				cond_attr(att,'max').to_i
			p.bandwidth_used = cond_attr(att,'used') &&
				cond_attr(att,'used').to_i
		end
		if els['/user/filesize']
			att = els['/user/filesize'].attributes
			p.filesize_max = cond_attr(att,'max') &&
				cond_attr(att,'max').to_i
		end

		p.upload_fetched = true if p.bandwidth_max

		flickr.person_cache_store(p) if flickr
		return p
	end

	private
	def self.cond_text(elements,index)
		elements[index] ? elements[index].text : nil
	end

	def self.cond_attr(attributes,name) attributes[name] end
end

class Flickr::Size
	attr_reader :label,:width,:height,:source,:url

	def initialize(label,width,height,source,url)
		@label = label
		@width = width
		@height = height
		@source = source
		@url = url
	end

	def self.from_xml(xml)
		att = xml.attributes
		return Flickr::Size.new(att['label'],att['width'].to_i,
			att['height'].to_i,att['source'],att['url'])
	end
end

class Flickr::Photo
	attr_accessor :id, :owner_id, :secret, :server, :title, :ispublic,
		:isfriend, :isfamily, :ownername, :dateadded,
		:license_id, :description, :dates, :taken,
		:lastupdate, :takengranularity, :cancomment, :canaddmeta,
		:comments, :rotation, :notes, :urls, :permaddmeta,
		:permcomment, :originalformat

	attr_reader :flickr

	def owner() @owner ||= @flickr.people.getInfo(owner_id) end
	def sizes() @sizes || @flickr.photos.getSizes(self).sizes end
	def sizes=(sizes) @sizes = sizes end

	def max_size
		sizes[:Original] ||  sizes[:Large] || sizes[:Medium] ||
			sizes[:Small]
	end

	def initialize(flickr,id)
		@flickr = flickr
		@id = id
	end

	def exif() @exif ||= @flickr.photos.getExif(self) end
	def exif=(set) @exif = set end

	def tags() @tags ||= @flickr.tags.getListPhoto(self) end
	def tags=(set) @tags = set end

	def license() @flickr.photos.licenses.getInfo[@license_id] end

	def contexts() @contexts ||= @flickr.photos.getAllContexts(self) end

	def url(size=nil)
		base = 'http://static.flickr.com'
		ext = (size == 'o') ? self.originalformat : 'jpg'
		return size ?
			"#{base}/#@server/#{@id}_#{@secret}_#{size}.#{ext}" :
			"#{base}/#@server/#{@id}_#{@secret}.jpg"
	end

	def delete() @flickr.photos.delete(self) end

	def self.from_xml(xml,flickr=nil)
		att = xml.attributes
		phid = att['id']

		photo = flickr.photo_cache_lookup(phid) if flickr
		photo ||= Flickr::Photo.new(flickr,phid)

		photo.owner_id ||= att['owner'] || (xml.elements['owner'] &&
			 xml.elements['owner'].attributes['nsid'])
		photo.secret = att['secret'] if att['secret']
		photo.originalformat = att['originalformat'] if
			att['originalformat']
		photo.server = att['server'].to_i if att['server']
		photo.title = att['title'] || cond_text(xml.elements,'title')
		photo.license_id = att['license']
		photo.rotation = att['rotation'].to_i if att['rotation']

		photo.ispublic = (att['ispublic'].to_i == 1) if att['ispublic']
		photo.isfriend = (att['isfriend'].to_i == 1) if att['isfriend']
		photo.isfamily = (att['isfamily'].to_i == 1) if att['isfamily']
		photo.ownername = att['ownername'] || (xml.elements['owner'] &&
			 xml.elements['owner'].attributes['username'])
		photo.description = cond_text(xml.elements,'description')
		photo.dateadded = Time.at(att['dateadded'].to_i) if
			att['dateadded']
		if xml.elements['exif']
			list = []
			xml.elements.each('exif') do |el|
				exif = Flickr::Exif.from_xml(el)
				list << exif
			end
			photo.exif = list
		end
		if xml.elements['visibility']
			att = xml.elements['visibility'].attributes
			photo.ispublic = (att['ispublic'].to_i == 1)
			photo.isfriend = (att['isfriend'].to_i == 1)
			photo.isfamily = (att['isfamily'].to_i == 1)
		end
		if xml.elements['dates']
			att = xml.elements['dates'].attributes
			dates = {}
			dates[:posted] = Time.at(att['posted'].to_i)
			dates[:taken] = Time.gm(*ParseDate.parsedate(att['taken']))
			dates[:lastupdate] = Time.at(att['lastupdate'].to_i)
			dates[:takengranularity] = att['takengranularity'].to_i
			photo.dates = dates
		end
		if xml.elements['editability']
			att = xml.elements['editability'].attributes
			photo.cancomment = (att['cancomment'].to_i == 1)
			photo.canaddmeta = (att['canaddmeta'].to_i == 1)
		end
		photo.comments = cond_text(xml.elements,'comments')
		photo.comments &&= photo.comments.to_i
		if xml.elements['notes']
			notes = []
			xml.elements['notes'].each_element do |el|
				notes << Flickr::Note.from_xml(el,photo)
			end
			photo.notes = notes
		end
		if xml.elements['tags']
			tags = []
			xml.elements['tags'].each_element do |el|
				tags << Flickr::Tag.from_xml(el,photo)
			end
			photo.tags = tags
		end
		if xml.elements['urls']
			urls = {}
			xml.elements['urls'].each_element do |el|
				att = el.attributes
				urls[att['type'].intern] = el.text
			end
			photo.urls = urls
		end
			
		flickr.photo_cache_store(photo) if flickr
		return photo
	end

	private
	def self.cond_text(elements,index)
		elements[index] ? elements[index].text : nil
	end
end

class Flickr::Exif
	attr_reader :tagspace,:tagspaceid,:tag,:label
	attr_accessor :raw,:clean
	def initialize(tagspace,tagspaceid,tag,label)
		@tagspace = tagspace
		@tagspaceid = tagspaceid
		@tag = tag
		@label = label
	end

	def self.from_xml(element)
		att = element.attributes
		exif = Flickr::Exif.new(att['tagspace'],att['tagspaceid'].to_i,
			att['tag'],att['label'])
		exif.raw=element.elements['raw'].text if element.elements['raw']
		exif.clean=element.elements['clean'].text if
			element.elements['clean']
		return exif
	end
end

class Flickr::PhotoList < Array
	attr_reader :page,:pages,:perpage,:total

	def initialize(page,pages,perpage,total)
		@page = page
		@pages = pages
		@perpage = perpage
		@total = total
	end

	def self.from_xml(xml,flickr=self)
		att = xml.root.attributes
		list = Flickr::PhotoList.new(att['page'].to_i,att['pages'].to_i,
			att['perpage'].to_i,att['total'].to_i)
		xml.elements['/photos'].each_element do |e|
			list << Flickr::Photo.from_xml(e,flickr)
		end
		return list
	end
end

class Flickr::Category
	attr_reader :name, :path, :pathids, :groups, :subcats, :id

	def initialize(name,path,pathids)
		@name = name
		@path = path
		@pathids = pathids
		@groups = []
		@subcats = []
		@id = pathids.split('/').last
	end
end

class Flickr::SubCategory
	attr_reader :name, :id, :count

	def initialize(name,id,count)
		@name = name
		@id = id
		@count = count
	end
end

class Flickr::Group
# The privacy attribute is 1 for private groups, 2 for invite-only public
# groups and 3 for open public groups.
	PRIVACY = [nil,:private,:invite,:public]

	attr_accessor :nsid, :name, :members, :online, :chatnsid, :inchat,
		:description, :privacy, :eighteenplus, :fully_fetched, :admin,
		:photo_count, :iconserver

	def initialize(flickr,nsid, name=nil, members=nil, online=nil,
			chatnsid=nil, inchat=nil)
		@flickr = flickr
		@nsid = nsid
		@name = name
		@members = members
		@online = online
		@chatnsid = chatnsid
		@inchat = inchat
		@fully_fetched = false
	end
	
	def full_info
		self.fully_fetched ? self : @flickr.groups.getInfo(self)
	end
end

class Flickr::GroupList < Array
	attr_reader :page,:pages,:perpage,:total

	def initialize(page,pages,perpage,total)
		@page = page
		@pages = pages
		@perpage = perpage
		@total = total
	end
end

class Flickr::Context
	attr_reader :prev_id,:prev_secret,:prev_title,:prev_url,
	            :next_id,:next_secret,:next_title,:next_url

	def initialize(prev_id,prev_secret,prev_title,prev_url,
	               next_id,next_secret,next_title,next_url)
		@prev_id = prev_id
		@prev_secret = prev_secret
		@prev_title = prev_title
		@prev_url = prev_url
		@next_id = next_id
		@next_secret = next_secret
		@next_title = next_title
		@next_url = next_url
	end

	def self.from_xml(xml)
		a0 = xml.elements['prevphoto'].attributes
		a1 = xml.elements['nextphoto'].attributes
		return Flickr::Context.new(
			a0['id'],a0['secret'],a0['title'],a0['url'],
			a1['id'],a1['secret'],a1['title'],a1['url'])
	end
end

class Flickr::License
	attr_reader :id, :name, :url
	def initialize(id,name,url)
		@id = id
		@name = name
		@url = url
	end

	def self.from_xml(xml)
		att = xml.attributes
		return Flickr::License.new(att['id'],att['name'],
				att['url'])
	end
end

class Flickr::Note
	attr_accessor :photo, :x, :y, :w, :h, :text, :id, :author_id
	def initialize(x, y, w, h, text, flickr = nil)
		@x = x
		@y = y
		@w = w
		@h = h
		@text = text
		@flickr = flickr
	end

	def author() @author_id && @flickr.people.getInfo(@author_id) end

	def from_xml(xml,photo=nil)
		att = xml.attributes
		note = Flickr::Note.new(att['x'].to_i,att['y'].to_i,
			att['w'].to_i,att['h'].to_i,xml.text,
			photo && photo.flickr)
		note.photo = photo
		note.id = att['id']
		note.author_id = att['author'] if att['author']
	end
end

class Flickr::Count
	attr_reader :fromdate, :todate, :count
	def initialize(count,fromdate,todate)
		@count = count
		@fromdate = fromdate
		@todate = todate
	end
	
	def self.from_xml(xml)
		att = xml.attributes
		return Flickr::Count.new(att['count'].to_i,
				Time.at(att['fromdate'].to_i),
				Time.at(att['todate'].to_i))
	end
end

class Flickr::Tag
	attr_reader :id, :author_id, :raw, :clean

	def initialize(flickr, id,author_id,raw,clean)
		@flickr = flickr
		@id = id
		@author_id = author_id
		@raw = raw
		@clean = clean
	end

	def author() @flickr.people.getInfo(@author_id) end

	def self.from_xml(xml,flickr=nil)
		att = xml.attributes
		clean = xml.text
		return Flickr::Tag.new(flickr,att['id'],att['author'],
			att['raw'], clean)
	end
end

class Flickr::PhotoSet < Array
	attr_accessor :id, :title, :url, :server, :primary_id,
		:photo_count, :description, :secret, :owner

	def initialize(id,flickr)
		@id = id
		@flickr = flickr
	end

	def <<(photo,raw=false)
		raw ? super(photo) : @flickr.photosets.addPhoto(self,photo)
		return self
	end

	def fetch(extras=nil)
		return self if @fetched
		set = @flickr.photosets.getPhotos(self,extras)
		@fetched = true
		return set
	end

	alias photos fetch

	def self.from_xml(xml,flickr=nil)
		att = xml.attributes
		psid = att['id']

		set = flickr.photoset_cache_lookup(psid) if flickr
		set ||= Flickr::PhotoSet.new(psid,flickr)

		set.secret = att['secret']
		set.owner = att['owner']
		set.url = att['url']
		set.server = att['server'].to_i
		set.primary_id = att['primary'].to_i
		set.photo_count = att['photos'].to_i
		set.title = xml.elements['title'].text if xml.elements['title']
		set.description = xml.elements['description'].text if
			xml.elements['description']
		if xml.elements['photo']
			set.clear
			xml.elements.each('photo') do |el|
				set.<<(Flickr::Photo.from_xml(el,flickr),true)
			end
		end

		flickr.photoset_cache_store(set) if flickr
		return set
	end

	def url
		owner = @owner || @flickr.photosets.getInfo(self).owner
		return "http://www.flickr.com/photos/#{owner}/sets/#{@id}"
	end

	def primary() @primary ||= @flickr.photos.getInfo(@primary_id) end
end

class Flickr::PhotoPool < Array
	attr_accessor :page, :pages, :perpage, :total, :title, :id

	def initialize(id,flickr)
		@id = id
		@flickr = flickr
	end

	def <<(photo,raw=false)
		raw ? super(photo) : @flickr.photosets.addPhoto(self,photo)
		return self
	end

	def fetch(extras=nil)
		return self if @fetched
		pool = @flickr.groups.pools.getPhotos(self,nil,extras,500)
		@fetched = true
		return pool
	end

	def self.from_xml(xml,flickr=nil)
		att = xml.attributes
		ppid = att['id']

		pool = flickr.photopool_cache_lookup(ppid)
		pool ||= Flickr::PhotoPool.new(ppid,flickr)

		pool.page = att['page'].to_i if att['page']
		pool.pages = att['pages'].to_i if att['pages']
		pool.perpage = att['perpage'].to_i if att['perpage']
		pool.total = att['total'].to_i if att['total']
		if xml.elements['photo']
# I'd like to clear the pool, but I can't because I don't know if I'm
# parsing the full set or just a single "page".
#			pool.clear
			xml.elements.each('photo') do |el|
				pool.<<(Flickr::Photo.from_xml(el,flickr),true)
			end
		end

		flickr.photopool_cache_store(pool) if flickr
		return pool
	end
end
