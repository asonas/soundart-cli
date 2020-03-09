require "soundart/version"
require "soundcloud"
require "taglib"
require 'open-uri'

module Soundart
  class Cli
    def self.start(argv)
      new(argv).run
    end

    def initialize(argv)
      @argv = argv.dup
      @url = argv.shift
      @response = nil
    end

    def run
      client = SoundCloud.new(client_id: ENV.fetch("SOUNDCLOUD_CLIENT_ID"))

      res = client.get("/resolve", url: @url)
      sound_track = case res
      when SoundCloud::ArrayResponseWrapper
        res.first
      when Hashie::Hash
        res
      else
        fail "Unknown Response: class #{res.class}"
      end

      options = "-o './%(extractor)s/%(id)s/%(title)s.%(ext)s' --write-thumbnail --write-description --write-info-json"

      result = `youtube-dl #{options} "#{@url}"`

      last_directory_path = "./soundcloud/#{sound_track['id']}/"

      track = JSON.parse(`youtube-dl --dump-json "#{@url}"`)
      music = `ls #{last_directory_path}/*.#{track['ext']}`.gsub("\n", '')

      case track["ext"]
      when "wav"
        `ffmpeg -i #{music} -vn -ac 2 -ar 44100 -ab 256k -y -acodec libmp3lame -f mp3 "#{music.gsub('wav', 'mp3')}"`
        music = music.gsub("wav","mp3")
      end

      TagLib::MPEG::File.open(music) do |file|
        tag = file.id3v2_tag

        tag.title = track['fulltitle']
        tag.artist = track['uploader']

        pic = TagLib::ID3v2::AttachedPictureFrame.new

        cover_art = music.gsub(track['ext'], 'jpg')
        if File.exists?(cover_art)
          pic.picture = File.open(cover_art, 'rb') { |f| f.read }
        else
          # ユーザのアバターをセットさせる
          open(sound_track["user"]["avatar_url"].gsub(/(large|original)/, 't500x500')) do |f|
            pic.picture = f.read
          end
        end

        pic.mime_type = "image/jpeg"
        pic.type = TagLib::ID3v2::AttachedPictureFrame::FrontCover

        tag.add_frame(pic)
        file.save
      end
    end

    # def run
    #   url = @argv.shift
    #   @response = SoundCloudClient.resolve(url)
    #   @track = SoundCloudClient.track(url)
    #   YoutubeDl.execute(@response)
    #   ArtWork.attach(@response)
    # end

    class SoundCloudClient
      def self.resolve(url)
        new(url).run
      end

      def self.track(url)
        new(url).track
      end

      def initialize(url)
        @url = url
        @client = SoundCloud.new(client_id: ENV.fetch("SOUNDCLOUD_CLIENT_ID"))
      end

      def track
        track = JSON.parse(`youtube-dl --dump-json "#{@url}`)
      end

      def resolve
        res = @client.get("/resolve", url: @url)
        case res
        when SoundCloud::ArrayResponseWrapper
          res
        when Hashie::Hash
          res
        else
          raise "Unknown response: #{res.inspect}"
        end
      end
    end

    class ArtWork
      def self.attach(response)
        new(response).attach
      end

      def initialise(response)
        @response = response
      end

      def attach
        TagLib::MPEG::File.open(music) do |file|
          tag = file.id3v2_tag

          tag.title = track['fulltitle']
          tag.artist = track['uploader']

          pic = TagLib::ID3v2::AttachedPictureFrame.new

          cover_art = music.gsub(track['ext'], 'jpg')
          if File.exists?(cover_art)
            pic.picture = File.open(cover_art, 'rb') { |f| f.read }
          else
            # ユーザのアバターをセットさせる
            open(sound_track["user"]["avatar_url"].gsub("large", 't500x500')) do |f|
              pic.picture = f.read
            end
          end

          pic.mime_type = "image/jpeg"
          pic.type = TagLib::ID3v2::AttachedPictureFrame::FrontCover

          tag.add_frame(pic)
          file.save
        end
      end
    end

    class Stuff
      def initialize(response)
        @response = response
      end

      def base_path
        "./soundcloud/#{@response['id']}/"
      end

      def ext
        @ext ||= @response['original_format']
      end

      def ext=(new_value)
        @ext = new_value
      end

      def filename
        "#{@response['title']}.#{ext}"
      end

      def artwork_url
        @response["artwork_url"] || @response["user"]["avatar_url"].gsub("large", 't500x500')
      end

      def file_path
        Pathname.new("#{base_path}#{filename}")
      end

      def normalize_file_path(from)
        file_path.gsub(from, "mp3")
      end
    end

    class YoutubeDl
      DEFAULT_OPTIONS = [
        "-o ./soundcloud/%(id)s/%(title)s.%(ext)s",
        "--write-thubmnail",
        "--write-description",
        "--write-info-json"
      ]

      def self.execute(response)
        new(response).execute
      end

      def initialzie(response)
        @response = response
      end

      def execute
        system(
          "youtube-dl",
          response["permalink_url"],
          **DEFAULT_OPTIONS
        )

        normalize_format
      end

      def normalize_format
        track = JSON.parse(`youtube-dl --dump-json "#{@response["permalink_url"]}"`)
        case track["ext"]
        when "wav"
          `ffmpeg -i #{file_path} -vn -ac 2 -ar 44100 -ab 256k -y -acodec libmp3lame -f mp3 "#{normalize_file_path(track['ext'])}"`
        end
      end
    end
  end
end
