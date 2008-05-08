require 'flickr/base'

class Flickr::Notes < Flickr::APIBase
	def add(photo,x,y,w,h,text)
		photo = photo.id if photo.class == Flickr::Photo
		res = @flickr.call_method('flickr.photos.notes.add',
			'photo_id' => photo, 'note_x' => x, 'note_y' => y,
			'note_w' => w, 'note_h' => h, 'note_text' => text)
		return res.elements['/note'].attributes['id']
	end

	def delete(note)
		note = note.id if note.class == Flickr::Note
		res = @flickr.call_method('flickr.photos.notes.delete',
			'note_id' => note)
	end

	def edit(note,x,y,w,h,text)
		note = note.id if note.class == Flickr::Note
		res = @flickr.call_method('flickr.photos.notes.edit',
			'note_id' => note, 'note_x' => x, 'note_y' => y,
			'note_w' => w, 'note_h' => h, 'note_text' => text)
	end
end
