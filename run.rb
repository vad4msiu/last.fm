#encoding: UTF-8
require "rubygems"
require "bundler/setup"
require 'optparse'
require 'ostruct'

Bundler.require(:default)

options = OpenStruct.new
optparse = OptionParser.new do |opts|
  opts.banner = "Usage: example.rb [options]"

  opts.on("-f", '--file_name FILE_NAME', "Путь к файлу с артистами (каждый на новой строке)") do |n|
    options.file_name = n
  end
end
begin
  optparse.parse!
  mandatory = [:file_name]
  missing = mandatory.select{ |param| options.send(param).nil? }
  if not missing.empty?
    puts "Missing options: #{missing.join(', ')}"
    puts optparse
    exit
  end
rescue OptionParser::InvalidOption, OptionParser::MissingArgument
  puts $!.to_s
  puts optparse
  exit
end

artists = File.read(options.file_name).split("\n")
LastFM.api_key     = "b25b959554ed76058ac220b7b2e0a026"
LastFM.client_name = "My app"

# puts LastFM::Artist.get_top_albums(:artist => 'qweqweqwe')['topalbums']['album'].inspect
artists.each do |artist|
  response_get_top_albums = LastFM::Artist.get_top_albums(:artist => artist)
  if response_get_top_albums['error']
    puts "#{artist}: #{response_get_top_albums['message']}"
  else
    response_get_top_albums['topalbums']['album'].each do |album|
      response_get_info = LastFM::Album.get_info(:artist => artist, :album => album['name'])
      if response_get_info['error']
        puts "#{artist}: #{album['name']}: #{response_get_info['message']}"
      else
        if response_get_info['album']['tracks']['track']
          response_get_info['album']['tracks']['track'].each do |track|
            puts "#{artist} - #{track['name']}" if track.is_a? Hash
          end
        end
      end
    end
  end
end