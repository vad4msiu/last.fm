#encoding: UTF-8
require "rubygems"
require "bundler/setup"
require 'optparse'
require 'ostruct'

Bundler.require

# options = OpenStruct.new
# optparse = OptionParser.new do |opts|
#   opts.banner = "Usage: example.rb [options]"
# 
#   opts.on("-f", '--file_name FILE_NAME', "Путь к файлу с артистами (каждый на новой строке)") do |n|
#     options.file_name = n
#   end
# end
# begin
#   optparse.parse!
#   mandatory = [:file_name]
#   missing = mandatory.select{ |param| options.send(param).nil? }
#   if not missing.empty?
#     puts "Missing options: #{missing.join(', ')}"
#     puts optparse
#     exit
#   end
# rescue OptionParser::InvalidOption, OptionParser::MissingArgument
#   puts $!.to_s
#   puts optparse
#   exit
# end
# 
# artists = File.read(options.file_name).split("\n")
LastFM.api_key     = "b25b959554ed76058ac220b7b2e0a026"
LastFM.client_name = "My app"

# puts LastFM::Artist.get_top_albums(:artist => 'Chef')['topalbums']['album'].inspect

def check_album(params)
  params.is_a?(Hash) ? true : false
end

def check_track(params)
  params.is_a?(Hash) ? true : false
end

def check_top_albums(params)
  return false if params['error']
  return false unless params['topalbums']
  return false unless params['topalbums']['album'].is_a?(Array)
  return true
end

def check_album_info(params)  
  if params['error'].nil? && 
     params['album'] && 
     params['album']['tracks'] && 
     params['album']['tracks']['track'].is_a?(Array)
    true
  else
    false
  end
end

artists.each do |artist|
  top_albums = LastFM::Artist.get_top_albums(:artist => artist)
  break if check_top_albums(top_albums)

  top_albums['topalbums']['album'].each do |album|
    break if check_album(album)
    album_info = LastFM::Album.get_info(:artist => artist, :album => album['name'])
    break if check_album_info(info)
    
    album_info['album']['tracks']['track'].each do |track|
      puts "#{artist} - #{track['name']}" if track.is_a? Hash
    end
  end
end