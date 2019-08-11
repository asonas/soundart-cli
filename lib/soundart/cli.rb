require "soundart/version"

module Soundart
  class Cli
    class Error < StandardError; end

    def self.start(argv)
      new(argv).run
    end

    def initialize(argv)
      @argv = argv.dup
    end

    def run
      puts "hello world"
    end
  end
end
