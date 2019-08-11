require 'logger'

module Soundart
  def self.logger
    @logger ||=
      begin
        $stdout.sync = true
        Logger.new($stfout).tap do |l|
          l.lebel = Logger::INFO
        end
      end
  end
end
