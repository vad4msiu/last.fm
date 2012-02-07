#encoding: UTF-8
require "bundler/setup"
require 'net/http'
require 'open-uri'
require 'optparse'
require 'ostruct'
require 'fileutils'
Bundler.require

options = OpenStruct.new
optparse = OptionParser.new do |opts|
  opts.banner = "Usage: example.rb [options]"

  opts.on("-f", '--file_name FILE_NAME', "Путь к файлу с артистами (каждый на новой строке)") do |n|
    options.file_name = n
  end
  opts.on("-d", '--dir DIR_NAME', "Путь к директории куда буду сохраняться треки") do |n|
    options.dir_name = n
  end 

  opts.on("-l", '--lib_file_name LIB_FILE_NAME', "Путь файлу библиотеке (тот файл который выдается ключиком -o)") do |n|
    options.lib_file_name = n
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

module Vkontakte
  class Music
    def initialize
      @app_id = 1850196
      @secret_key = 'nk0n6I6vjQ'
      @user_id = 76347967
    end

    def find q
      path = "http://api.vk.com/api.php?api_id=%s&count=200&v=2.0&method=audio.search&sig=%s&test_mode=1&q=%s" % [@app_id, make_sig('audio.search', q), URI.escape(q)]

      doc = open(path) { |f| Hpricot(f) }

      mp3_url = (doc/:response/:audio/:url).first.inner_text rescue nil
      mp3_url
    end

    private

    def make_sig(method, query)
      str = "%sapi_id=%scount=200method=%sq=%stest_mode=1v=2.0%s" % [@user_id, @app_id, method, query, @secret_key]
      Digest::MD5.hexdigest(str)
    end
  end
end

LastFM.api_key     = "b25b959554ed76058ac220b7b2e0a026"
LastFM.client_name = "My app"

@lib_file = File.open(options.lib_file_name, "a+")
@lib_file_string = @lib_file.read
def find_in_lib(name)
  @lib_file_string.scan(name).first ? true : false
end

def check_album(params)
  params.is_a?(Hash) ? true : false
end

def check_track(params)
  params.is_a?(Hash) ? true : false
end

def check_top_albums(params)
  if params['error'].nil? &&
     params['topalbums'] &&
     params['topalbums']['album'].is_a?(Array)
    true
  else
    false
  end
end

def check_album_info(params)  
  if params['error'].nil? && 
     params['album'] && 
     params['album']['tracks'] && 
     (params['album']['tracks']['track'].is_a?(Array) || params['album']['tracks']['track'].is_a?(Hash))
    true
  else
    false
  end
end

artists.each do |artist|
  top_albums = LastFM::Artist.get_top_albums(:artist => artist)
  next unless check_top_albums(top_albums)
  top_albums['topalbums']['album'].each do |album|
    next unless check_album(album)
    album_info = LastFM::Album.get_info(:artist => artist, :album => album['name'])
    next unless check_album_info(album_info)
    album_info['album']['tracks']['track'] = [album_info['album']['tracks']['track']] if album_info['album']['tracks']['track'].is_a?(Hash)
    FileUtils.mkdir_p File.join(options.dir_name, artist, album['name'])
    album_info['album']['tracks']['track'].each do |track|
      new unless check_track(track)
      name = "#{artist} - #{track['name']}"
      unless find_in_lib(name)
        url = Vkontakte::Music.new.find name
        if url
          uri = URI.parse(url)
          file = File.new(File.join(options.dir_name, artist, album['name'], track['name'] + '.mp3'), "w")
          file.write(Net::HTTP.get(uri.host, uri.path))
          file.close
          @lib_file.write("#{name}\n")
          puts "Add: #{name}"
        end
      end
    end
  end
end

@lib_file.close