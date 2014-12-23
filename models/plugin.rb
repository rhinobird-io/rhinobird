class Plugin < ActiveRecord::Base
  require 'zip'
  require 'fileutils'
  require 'uuid'
  PLUGIN_DIR = 'plugins'

  validates :name, presence: true, uniqueness: true

  def self.load_from_zip(file)
    uuid = UUID.new.generate
    dir = File.join(PLUGIN_DIR, uuid)
    Zip::File.open(file) { |zip_file|
      zip_file.each { |f|
        f_path = File.join(dir, f.name)
        FileUtils.mkdir_p(File.dirname(f_path))
        zip_file.extract(f, f_path)
      }
    }
    config = JSON.parse(File.open(File.join(dir, 'plugin.json'), 'r').read)
    name = config['name']
    if File.exists?(File.join(PLUGIN_DIR, name))
      raise 'Plugin dir already exists!'
    end
    FileUtils.mv(dir, File.join(PLUGIN_DIR, name))
    self.new(config)
  end

  def start
    dir = File.join(PLUGIN_DIR, self.name)
    pid = spawn("ruby #{File.join(dir, 'app.rb')}", out: "#{File.join(dir, 'out.log')}", err: "#{File.join(dir, 'err.log')}")
    Process.detach(pid)
  end
end