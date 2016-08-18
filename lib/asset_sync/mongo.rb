require 'mime-types'
module AssetSync
  class Mongo
    def self.upload(config,file)
      p config.public_path
      puts file
      client = config.mongo
      fs = client.database.fs
      f = config.public_path.join(file)
      if File.exist?(f) && File.file?(f)
        client.database.fs.find(:filename => file).each do |i|
          client.database.fs.delete(i['_id'])
        end
        fn = open(f)
        content_type = `file --mime -b #{f}`.chomp
        content_type =   MIME::Type.simplified(content_type)
        fs.upload_from_stream(file, fn, content_type: content_type)
        fn.close
      end
    end
  end
end
