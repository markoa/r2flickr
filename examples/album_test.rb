#!/usr/bin/env ruby

t0 = Time.now
require 'flickr'

t1 = Time.now

flickr = Flickr.new('MY_TOKEN')

setname = ARGV.shift

sets = flickr.photosets.getList
t2 = Time.now
set = sets.find{|s| s.title == setname} # May be nil, we handle that later.
set &&= set.fetch
t3 = Time.now
set.each do |photo|
	str =<<EOF
<a href="#{photo.url}"><img src="#{photo.url('s')}" alt="#{photo.title}"></a>
EOF
	print str.strip+' '
end
t4 = Time.now

puts "\n\n\n"
puts "Library load: #{t1-t0} seconds"
puts "photosets.getList: #{t2-t1} seconds"
puts "Set fetching: #{t3-t2} seconds"
puts "Formatting: #{t4-t3} seconds"
puts "TOTAL: #{t4-t0} seconds"
