#!/usr/bin/env ruby

require 'flickr'

flickr = Flickr.new('MY_TOKEN')

sets = flickr.photosets.getList

# Get the sets that AREN'T comics and put them at the start.
flickr.photosets.orderSets(sets.find_all { |set| !(set.title =~ /^Comics /) })

# Get the latest comic set and make its photos invisible (I assume
# that since this runs daily, we only need to do the latest
# set...otherwise find_all.each would do the trick.
set = sets.find { |set| set.title =~ /^Comics / }
set.fetch.each { |p| flickr.photos.setPerms(p,false,false,false,0,0) }
