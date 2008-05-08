#!/usr/bin/env ruby

require 'flickr'

def filename_to_title(filename)
	arr = filename.split(File::SEPARATOR).last.split('.')
	arr.pop
	my_title = arr.join('.')
end

flickr = Flickr.new('MY_TOKEN')
#flickr.debug = true

setname = ARGV.shift
description = ARGV.shift

sets = flickr.photosets.getList
set = sets.find{|s| s.title == setname} # May be nil, we handle that later.
set &&= set.fetch

# These are photos we may have already uploaded but may or may not have
# added to this set.  A content-based signature would be better.  MD5?
tot = flickr.photos.getNotInSet(nil,1).total
pg = 1
nis = []
while (tot > 0)
	nis += flickr.photos.getNotInSet(nil,500,pg)
	pg += 1
	tot -= 500
end
eligible = (set ? set.fetch : []) + nis
to_upload = []
uploaded = []
ARGV.each do |filename|
	my_title = filename_to_title(filename)
	photo = eligible.find{|photo| photo.title==my_title}
	photo ? uploaded << photo : to_upload << filename
end

##uploaded += to_upload.map do |fname|
##	$stderr.puts "Uploading #{fname}..."
##	flickr.photos.getInfo(flickr.photos.upload.upload_file(fname))
##end

tix = to_upload.map do |fname|
	$stderr.puts "Uploading #{fname}..."
	flickr.photos.upload.upload_file_async(fname)
end

tix = flickr.photos.upload.checkTickets(tix)
while(tix.find_all{|t| t.complete==:incomplete }.length > 0)
	sleep 2
	puts "Checking on the following tickets: "+
		tix.map{|t| "#{t.id} (#{t.complete})"}.join(', ')
	tix = flickr.photos.upload.checkTickets(tix)
end

failed = tix.find_all{|t| t.complete == :failed}
failed.each { |f| $stderr.puts "Failed to upload #{to_upload[tix.index(f)]}." }
0.upto(tix.length - 1) { |n| puts "#{to_upload[n]}\t#{tix[n].photoid}" }

uploaded += tix.find_all{|t| t.complete == :completed}.map do |ticket|
	flickr.photos.getInfo(ticket.photoid)
end
uploaded.each do |photo|
	if set
		set << photo unless set.find{|ph| ph.id == photo.id}
	else
		set = flickr.photosets.create(setname,photo,description)
	end
end

# Refresh the list
set = set.fetch
ARGV.each do |filename|
	my_title = filename_to_title(filename)
	photo = uploaded.find{|ph| ph.title == my_title}
	puts "PIC=#{filename}\t#{photo.id}\t#{photo.url}" if photo
end
puts "SET=#{set.url}"
