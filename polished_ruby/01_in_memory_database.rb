album_infos = 100.times.flat_map do |i|
  10.times.map do |j|
    ["Album #{i}", j, "Artist #{j}"]
  end
end

album_artists = {}
album_track_artists = {}
album_infos.each do |album, track, artist|
  (album_artists[album] ||= []) << artist
  (album_track_artists[[album, track]] ||= []) << artist
end
album_artists.each_value(&:uniq!)

lookup = ->(album, track=nil) do
  if track
    album_track_artists[[album, track]]
  else
    album_artists[album]
  end
end

p lookup.("Album 5", 9)

albums = {}
album_infos.each do |album, track, artist|
  ((albums[album] ||= {})[track] ||= []) << artist
end

lookup_h = ->(album, track=nil) do
  if track
    albums.dig(album, track)
  else
    a = albums[album].each_value.to_a
    a.flatten!
    a.uniq!
    a
  end
end

p lookup_h.("Album 2")
