require 'flickr/base'

class Flickr::Method
	attr_reader :name,:authenticated,:description,:response,:explanation,
		:arguments, :errors

	def initialize(name,authenticated,description,response,explanation)
		@name = name
		@authenticated = authenticated
		@description = description
		@response = response
		@explanation = explanation
		@arguments = []
		@errors = []
	end
end

class Flickr::MethodArgument
	attr_reader :name, :optional, :description
	
	def initialize(name,optional,description)
		@name = name
		@optional = optional
		@description = description
	end
end

class Flickr::Reflection < Flickr::APIBase
	# We don't bother with caching because it's not worth it for the
	# reflection API.
	def getMethodInfo(method_name)
		res = @flickr.call_method('flickr.reflection.getMethodInfo',
			'method_name' => method_name)
		els = res.elements
		att = res.root.attributes
		desc = els['/method/description'] ?
			els['/method/description'].text : nil
		resp = els['/method/response'] ?
			els['/method/response'].text : nil
		expl = els['/method/explanation'] ?
			els['/method/explanation'].text : nil
		meth = Flickr::Method.new(att['name'],att['needslogin'].to_i==1,
			desc,resp,expl)
		els['/method/arguments'].each_element do |el|
			att = el.attributes
			arg = Flickr::MethodArgument.new(att['name'],
				att['optional'].to_i == 1,el.text)
			meth.arguments << arg
		end
		els['/method/errors'].each_element do |el|
			att = el.attributes
			err = XMLRPC::FaultException.new(att['code'].to_i,
				el.text)
			meth.errors << err
		end		
		return meth
	end

	def getMethods
		res = @flickr.call_method('flickr.reflection.getMethods')
		list = []
		res.elements['/methods'].each_element do |el|
			list << el.text
		end
		return list
	end

	def missing_methods
		list = []
		methods = self.getMethods
		methods.each do |mname|
			parts = mname.split('.')
			parts.shift
			call = parts.pop
			obj = @flickr
			parts.each do |part|
				if obj.respond_to?(part)
					obj = obj.method(part).call
				else
					obj = nil
					list << mname
					break
				end
			end
			list << mname if (obj && !obj.respond_to?(call))
		end
		return list
	end
end
