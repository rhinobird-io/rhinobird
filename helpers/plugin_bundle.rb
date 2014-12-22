class PluginBundle
  require 'zip'
  require 'fileutils'
  require 'uuid'
  PLUGIN_DIR = 'plugins'

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
    pid = spawn("ruby #{dir}/app.rb", out: "#{dir}/log.out", err: "#{dir}/log.err")
    Process.detach(pid)
  end
end