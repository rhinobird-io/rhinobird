require 'logger'

class MyLogger
    @@logger = Logger.new(STDOUT)

    @@logger.level = Logger::INFO

    @@logger.formatter = proc do |severity, datetime, progname, msg|
      "#{datetime} #{severity}: #{msg}\n"
    end

    def self.debug(msg)
      @@logger.debug(msg)
    end

    def self.info(msg)
      @@logger.info(msg)
    end

    def self.fatal(msg)
      @@logger.fatal(msg)
    end

    def self.warn(msg)
      @@logger.warn(msg)
    end

    def self.error(msg)
      @@logger.error(msg)
    end
end
