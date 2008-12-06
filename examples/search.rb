#!/usr/bin/env ruby

flickr = Flickr.new('MY_TOKEN')

puts "Enter a search query:"
query = gets

photos = flickr.photos.search(:text => query,
                              :per_page => 10, :page => 1,
                              :sort => "interestingness-desc")

for photo in photos
  puts photo.title()
  puts photo.url()
  puts
end
