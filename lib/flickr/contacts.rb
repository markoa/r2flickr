require 'flickr/base'

class Flickr::Contacts < Flickr::APIBase
	def getList(filter=nil)
		res = filter ?
			@flickr.call_method('flickr.contacts.getList') :
			@flickr.call_method('flickr.contacts.getList',
				'filter'=>filter)
		list = []
		res.elements['/contacts'].each_element do |e|
			att = e.attributes
			nsid = att['nsid']

			person = @flickr.person_cache_lookup(nsid)
			person ||= Flickr::Person.new(nsid,att['username'])

			person.realname = att['realname']
			person.friend = (att['friend'].to_i == 1)
			person.family = (att['family'].to_i == 1)
			person.ignored = (att['ignored'].to_i == 1)

			list << person

			@flickr.person_cache_store(person)
		end
		return list
	end

	# User can be either the NSID String or a Contact
	def getPublicList(user)
		user = user.nsid if user.class == Flickr::Person
		res = @flickr.call_method('flickr.contacts.getPublicList',
				'user_id'=>user)
		list = []
		res.elements['/contacts'].each_element do |e|
			att = e.attributes
			nsid = att['nsid']

			person = @flickr.person_cache_lookup(nsid)
			person ||= Flickr::Person.new(nsid,att['username'])

			person.ignored = (att['ignored'].to_i == 1)
			@flickr.person_cache_store(person)
			list << person
		end
		return list
	end
end
