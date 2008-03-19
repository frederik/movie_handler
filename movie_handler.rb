#!/usr/bin/env ruby

require 'cgi'
require 'net/http'
require 'ostruct'
require 'rubygems'
require 'rbosa'
require 'stringio'
require 'uri'

if ARGV.empty?
  puts "Need a Filename!"
  exit
end
if File.exists?(ARGV.first) 
  file = ARGV.first
else
  puts "Invalid Filename!"
  exit
end

file_types = ['.avi', '.divx', '.m4v', '.mov', '.mpg', '.mpeg', '.wmv']
file_types_itunes = ['.m4v', '.mov']

# no timeout and wait for reply
OSA.timeout = -2
OSA.wait_reply = true
OSA.utf8_strings = true

def add_to_itunes(movie)
  itunes = OSA.app('iTunes')
  begin
    itunes.activate
  rescue RuntimeError
    system('open -a "iTunes"')
    itunes.activate
  end
  
  track = itunes.add movie.file
  
  if movie.kind == :tvshow
    track.show = movie.show
    track.name = movie.name
    track.album = "#{movie.show}, Season #{movie.season.to_s}"
    track.genre = movie.genre
    track.season_number = movie.season
    track.episode_number = movie.episode
    track.episode_id = movie.season.to_s + (movie.episode < 10 ? "0" + movie.episode.to_s : movie.episode.to_s)
    track.year = movie.year
    track.track_number = movie.episode
    track.video_kind = OSA::ITunes::EVDK::TV_SHOW
    if file = get_cover_file(track.location)
      begin
        file = File.open(file)
        file.pos = 512 # skip header
        track.artworks.first.data = file.read
        file.close
      rescue
        puts "Error adding Cover"
      end
    end
  else
    track.name = movie.name
    track.year = movie.year
    track.video_kind = OSA::ITunes::EVDK::MOVIE
  end
end

def get_movie_details(file)
  movie = OpenStruct.new
  movie.file = file
  
  # parse filename
  name = File.basename(file, File.extname(file))
  if name =~ /[sS]{0,1}[0-9]{1,2}[eExX][0-9]{1,2}/ # nice episode "S03E12" or "4x02"
    movie.kind = :tvshow
    file_match = name.match(/[sS]{0,1}[0-9]{1,2}[eExX][0-9]{1,2}/)
    movie.show = file_match.pre_match.gsub(".", " ").strip
    movie.episode = file_match.to_s.match(/[0-9][0-9]$/).to_s.to_i
    movie.season = file_match.to_s.match(/[0-9][0-9]$/).pre_match.match(/[0-9]{1,2}/).to_s.to_i
    movie.episode_id = movie.season.to_s + (movie.episode < 10 ? "0" + movie.episode.to_s : movie.episode.to_s)
    movie.name = "Episode #{movie.episode.to_s}"
    movie.year = Time.now.year
  elsif name =~ /\D[0-9][0-9][0-9]\D/ # bad espisode "411"
    movie.kind = :tvshow
    file_match = name.match(/\D[0-9][0-9][0-9]\D/)
    movie.show = file_match.pre_match.gsub(".", " ").strip
    movie.episode = file_match.to_s.match(/[0-9][0-9]\D$/).to_s.to_i
    movie.season = file_match.to_s.match(/[0-9][0-9]\D$/).pre_match.match(/[0-9]{1,2}/).to_s.to_i
    movie.episode_id = movie.season.to_s + (movie.episode < 10 ? "0" + movie.episode.to_s : movie.episode.to_s)
    movie.name = "Episode #{movie.episode.to_s}"
    movie.year = Time.now.year
  elsif name =~ /[0-9][0-9][0-9][0-9]/ # year number. should be a movie
    movie.kind = :movie
    movie.name = name.match(/[\[\(]{0,1}[0-9][0-9][0-9][0-9]/).pre_match.gsub(".", " ").strip
    movie.year = name.match(/[0-9][0-9][0-9][0-9]/).to_s.to_i
  else
    movie.kind = :movie
    movie.name = name
    movie.year = Time.now.year
  end
  
  if movie.kind == :tvshow
    movie = get_details_from_tvrage(movie)
  end

  movie
end

# fetch tvshow details form tvrage.com
def get_details_from_tvrage(show)
  # prepare URI
  url = URI::HTTP.build(:host => 'www.tvrage.com', :path => '/quickinfo.php', :query => ('show=' + CGI.escape(show.show) + '&ep=' + show.season.to_s + 'x' + show.episode.to_s))
  begin
    response = StringIO.new(Net::HTTP.get(url))
    while !response.eof?
      line = response.gets
      line = line.split(/[@\n\^\|]/)
      puts line.inspect
      case line.first
      when 'Show Name'
        show.show = line[1]
      when 'Show URL'
        show.url = line[1]
      when 'Genres'
        show.genre = line[1].strip # taking only first into account
      when 'Episode Info'
        show.name = line[2]
        begin
          show.year = Date.parse(line[3]).year
        rescue ArgumentError
        end
      end
    end
  rescue Net::HTTPExceptions
  end

  show
end

# save movie as .mov
def save_movie_as_mov(file_old, file_new)
  qt = OSA.app('QuickTime Player')
  begin
    qt.activate
  rescue RuntimeError
    system('open -a "QuickTime Player"')
    qt.activate
  end
  movie = qt.open(file_old).first
  puts movie.inspect
  movie.save_self_contained file_new
  qt.quit
end

def delete_file(file)
  begin
    File.delete(file)
    puts "Deleted File #{file}"
  rescue
  end
end

def get_cover_file(location)
  file = File.expand_path("~/Pictures") + "/Cover/" + File.dirname(location).split("/").last + ".pict"
  return File.exists?(file) ? file : false
end

def get_mov_file_name(file)
  return File.expand_path("~/Movies") + "/" + File.basename(file, File.extname(file)) + ".mov"
end

if file_types.include?(File.extname(file))
  unless file_types_itunes.include?(File.extname(file))
    puts "Saving Movie as .mov"
    mov_file = get_mov_file_name(file)
    puts mov_file
    save_movie_as_mov(file, mov_file)
    delete_file(file)
    file = mov_file
  end

  puts "Fetching Movie Details"
  movie = get_movie_details(file)
  puts movie.inspect
  puts "Adding Movie to iTunes"
  add_to_itunes(movie)
  delete_file(file)
else
  puts "Invalid File Name or Type"
end