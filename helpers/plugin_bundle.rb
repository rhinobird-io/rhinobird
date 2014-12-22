class PluginBundle
  require 'zip'
  require 'fileutils'
  require 'uuid'
  PLUGIN_DIR = 'plugins'

  def self.load_from_zip(file)
    uuid = UUID.new.generate
    Zip::File.open(file) { |zip_file|
      zip_file.each { |f|
        f_path = File.join(PLUGIN_DIR, uuid, f.name)
        FileUtils.mkdir_p(File.dirname(f_path))
        zip_file.extract(f, f_path)
      }
    }
  end
end