module Utilities
  
  def input_file(file_path)
    file_path.split('/').last
  end

  def make_directory(target)
    Dir.mkdir(target) unless File.exists?(target)
  end

  def download_file(local, remote)
    foo = File.new(local, File::CREAT|File::RDWR)
    hash = Aws.s3i.get(Aws.bucket_name, remote) do |chunk|
      foo.write(chunk)
    end
    foo.close
    hash
  end

  def remove_item(directory)
    FileUtils.rm_r(directory) if File.exists?(directory)
  end

  def send_file(file)
    success = Aws.put_object(bucket_object(file), File.open(file), {"x-amz-acl" => "public-read"})
  end
  
  def unzip_file(source, target)
    Zip::ZipFile.open(source) do |zipfile|
      dir = zipfile.dir
      dir.entries('.').each do |entry|
        zipfile.extract(entry, "#{target}/#{entry}")
      end
    end
    rescue Zip::ZipDestinationFileExistsError => ex
      nil
      # I'm going to ignore this and just overwrite the files.
  end
end
