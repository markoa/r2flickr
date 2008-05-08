#!/usr/bin/env ruby

require 'flickr'

class Flickr::Relatedness
	attr_reader :photos

	def initialize(photo)
		@photo = photo
		@threads = []
	end

	def calc_relatedness
		@threads.each { |th| th.kill }
		@threads = []
		@photos = {}
		walk_tree(0,@photo)
		thread_join
		@photos = @photos.sort{|a,b| b[1]<=>a[1]}.map{|a|
			Flickr::Photo.new(@photo.flickr,a[0]) }
		return self
	end

	def [](i,j=nil)
		return j ? @photos[i,j] : @photos[i]
	end

	private

	def thread_dead_collect
		threads = @threads.dup
		threads.each { |th| @threads.delete(th) unless th.alive? }
	end

	def thread_join(max = 0)
		threads = @threads.dup
		threads.each do |th|
			@threads.delete(th)
			th.join
			break if @threads.length <= max
		end
	end

	def walk_tree(depth,photo)
		photo.contexts.each do |ctx|
#		thread_join(10) if @threads.length >= 20
			p = proc {
$stderr.puts "#{ctx.title} (#{ctx.class})"
				set = ctx.fetch
				set.each do |ph|
					walk_tree(depth-1,ph) if depth > 0
					@photos[ph.id] ||= 0
					@photos[ph.id] += 1
				end
			}
			thread_dead_collect
			if @threads.length >= 20
				p.call
			else
				th = Thread.new { p.call }
				@threads << th
			end
		end
	end
end
