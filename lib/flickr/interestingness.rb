require 'flickr/base'

class Flickr::Interestingness < Flickr::APIBase
	def getList(date=nil,extras=nil,per_page=nil,page=nil)
		args = {}
		if date
			args['date'] = date if date.is_a?(String)
			args['date'] = date.to_s if date.is_a?(Date)
			args['date'] = @flickr.mysql_date(date) if
				date.is_a?(Time)
		end
		extras = extras.join(',') if extras.class == Array
		args['extras'] = extras if extras
		args['per_page'] = per_page if per_page
		args['page'] = page if page
                res = @flickr.call_method('flickr.interestingness.getList',args)
		return Flickr::PhotoSet.from_xml(res.root,@flickr)
	end
end
