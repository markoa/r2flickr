require 'flickr/base'
require 'mime/types'
require 'net/http'

class Flickr::Ticket
	attr_reader :id
	attr_accessor :complete, :invalid, :photoid

	COMPLETE=[:incomplete,:completed,:failed]

	def initialize(id,upload)
		@id = id
		@upload = upload
	end

	def check
		t = @upload.checkTickets(self)[0]
		self.complete = t.complete
		self.invalid = t.invalid
		self.photoid = t.photoid
		return t
	end
end

class Flickr::FormPart
	attr_reader :data, :mime_type, :attributes

	def initialize(name,data,mime_type=nil)
		@attributes = {}
		@attributes['name'] = name
		@data = data
		@mime_type = mime_type
	end

	def to_s
		([ "Content-Disposition: form-data" ] +
		attributes.map{|k,v| "#{k}=\"#{v}\""}).
		join('; ') + "\r\n"+
		(@mime_type ? "Content-Type: #{@mime_type}\r\n" : '')+
		"\r\n#{data}"
	end
end

class Flickr::MultiPartForm
	attr_accessor :boundary, :parts

	def initialize(boundary=nil)
		@boundary = boundary ||
		    "----------------------------Ruby#{rand(1000000000000)}"
		@parts = []
	end

	def to_s
		"--#@boundary\r\n"+
		parts.map{|p| p.to_s}.join("\r\n--#@boundary\r\n")+
		"\r\n--#@boundary--\r\n"
	end
end

class Flickr::Upload < Flickr::APIBase

  # TODO: It would probably be better if we wrapped the fault
  # in something more meaningful. At the very least, a broad
  # division of errors, such as retryable and fatal. 
	def error(el)
		att = el.attributes
		fe = XMLRPC::FaultException.new(att['code'].to_i,
				att['msg'])
		$stderr.puts "ERR: #{fe.faultString} (#{fe.faultCode})"
		raise fe
	end

	def prepare_parts(data,mimetype,filename,title=nil,description=nil,
			tags=nil, is_public=nil,is_friend=nil,is_family=nil,
			sig=nil, async=nil)
		parts = []
		parts << Flickr::FormPart.new('title',title) if title
		parts << Flickr::FormPart.new('description',description) if
			description
		parts << Flickr::FormPart.new('tags',tags.join(',')) if tags
		parts << Flickr::FormPart.new('is_public',
			is_public ?  '1' : '0') if is_public != nil
		parts << Flickr::FormPart.new('is_friend',
			is_friend ?  '1' : '0') if is_friend != nil
		parts << Flickr::FormPart.new('is_family',
			is_family ?  '1' : '0') if is_family != nil
		parts << Flickr::FormPart.new('async',
			async ?  '1' : '0') if async != nil

		parts << Flickr::FormPart.new('api_key',@flickr.api_key)
		parts << Flickr::FormPart.new('auth_token',
				@flickr.auth.token.token)
		parts << Flickr::FormPart.new('api_sig',sig)

		parts << Flickr::FormPart.new('photo',data,mimetype)
		parts.last.attributes['filename'] = filename
		return parts
	end

	def make_signature(title=nil,description=nil, tags=nil,
			is_public=nil,is_friend=nil,is_family=nil,async=nil)
		args = {'api_key' => @flickr.api_key,
			'auth_token' => @flickr.auth.token.token}
		args['title'] = title if title
		args['description'] = description if description
		args['tags'] = tags.join(',') if tags
		args['is_public'] = (is_public ? '1' : '0') if is_public != nil
		args['is_friend'] = (is_friend ? '1' : '0') if is_friend != nil
		args['is_family'] = (is_family ? '1' : '0') if is_family != nil
		args['async'] = (async ? '1' : '0') if async != nil
		args['api_sig'] = @flickr.sign(args)
	end

	def send_form(form)
		headers = {"Content-Type" =>
			"multipart/form-data; boundary=" + form.boundary}

		http = Net::HTTP.new('www.flickr.com', 80)
#		http.read_timeout = 900 # 15 minutes max upload time
		tries = 3
		begin
			res=http.post('/services/upload/',form.to_s,headers)
		rescue Timeout::Error => err
			tries -= 1
			$stderr.puts "Timed out, will retry #{tries} more."
			retry if tries > 0
			raise err
		end
		return res
	end

	def upload_file_async(filename,title=nil,description=nil,tags=nil,
			is_public=nil,is_friend=nil,is_family=nil)
		mt = MIME::Types.of(filename)
		f = File.open(filename,'rb')
		data = f.read
		f.close
		return upload_image_async(data,mt,filename,title,description,
				tags, is_public,is_friend,is_family)
	end


	def upload_file(filename,title=nil,description=nil,tags=nil,
			is_public=nil,is_friend=nil,is_family=nil)
		mt = MIME::Types.of(filename)
		f = File.open(filename,'rb')
		data = f.read
		f.close
		return upload_image(data,mt,filename,title,description,tags, 
				is_public,is_friend,is_family)
	end

	def upload_image_async(data,mimetype,filename,title=nil,description=nil,
			tags=nil, is_public=nil,is_friend=nil,is_family=nil)
		form = Flickr::MultiPartForm.new

		sig = make_signature(title,description, tags, is_public,
				is_friend, is_family, true)
		form.parts += prepare_parts(data,mimetype,filename,title,
				description, tags, is_public, is_friend,
				is_family, sig, true)
		res = REXML::Document.new(send_form(form).body)
		error(res.elements['/rsp/err']) if res.elements['/rsp/err']
		t = Flickr::Ticket.new(res.elements['/rsp/ticketid'].text, self)
		@flickr.ticket_cache_store(t)
		return t
	end

	def upload_image(data,mimetype,filename,title=nil,description=nil,
			tags=nil, is_public=nil,is_friend=nil,is_family=nil)
		form = Flickr::MultiPartForm.new

		sig = make_signature(title,description, tags, is_public,
				is_friend, is_family)
		form.parts += prepare_parts(data,mimetype,filename,title,
				description, tags, is_public, is_friend,
				is_family, sig)
		res = REXML::Document.new(send_form(form).body)
		error(res.elements['/rsp/err']) if res.elements['/rsp/err']
		val = res.elements['/rsp/photoid'].text
		return val
	end

	def checkTickets(tickets)
		tickets = [tickets] if tickets.class != Array
		targ = tickets.map{|t|
			t.id.to_s if t.class == Flickr::Ticket }.join(',')
		res = @flickr.call_method('flickr.photos.upload.checkTickets',
			'tickets' => targ)
		tickets = []
		res.elements['/uploader'].each_element('ticket') do |tick|
			att = tick.attributes
			tid = att['id']
			t = @flickr.ticket_cache_lookup(tid) ||
				Flickr::Ticket.new(tid,self)
			t.complete = Flickr::Ticket::COMPLETE[att['complete'].to_i]
			t.photoid = att['photoid']
			t.invalid = true if (att['invalid'] &&
				(att['invalid'].to_i == 1))
			@flickr.ticket_cache_store(t)
			tickets << t
		end
		return tickets
	end
end
