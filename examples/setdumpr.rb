#!/usr/bin/env ruby
# Dump a Ruby marshalled file of all photos by set (and not in set)

require 'flickr'

flickr = Flickr.new('MY_TOKEN')
allsets = flickr.photosets.getList

filename = ARGV.shift or raise Exception.new('Need output filename')

# This really won't hack it if you have more than 500, but then you're
# probably not using this.  I am.
notinsets = flickr.photos.getNotInSet(nil,500)

# Stripped down analog of the Flickr::Photo class
PhotoInfo = Struct.new('PhotoInfo',:title,:id,:secret,:server)

sethash = {}
allsets.each do |set|
	set = flickr.photosets.getInfo(set)
	photohash = {}
	seturl = "http://www.flickr.com/photos/#{set.owner}/sets/#{set.id}"
	sethash[set.title] = [seturl,photohash]
	flickr.photosets.getPhotos(set).each do |photo|
		phi = PhotoInfo.new
		phi.title = photo.title
		phi.secret = photo.secret
		phi.server = photo.server
		phi.id = photo.id
		photohash[phi.title] = phi
	end
end

photohash = {}
sethash[nil] = photohash
notinsets.each do |photo|
	phi = PhotoInfo.new
	phi.title = photo.title
	phi.secret = photo.secret
	phi.server = photo.server
	phi.id = photo.id
	photohash[phi.title] = phi
end

#$stderr.puts sethash.inspect
File.open(filename,'w') { |f| Marshal.dump(sethash,f) }
