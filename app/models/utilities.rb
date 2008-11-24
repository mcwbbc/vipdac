module Utilities

  def ignore?(exception) #:nodoc:
    ignore_these = HoptoadNotifier.ignore.flatten
    ignore_these.include?(exception.class) || ignore_these.include?(exception.class.name)
  end
  
  def input_file(file_path)
    file_path.split('/').last
  end

  def make_directory(target)
    Dir.mkdir(target) unless File.exists?(target)
  end

  def remove_item(directory)
    FileUtils.rm_r(directory) if File.exists?(directory)
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

  def download_file(local, remote)
    foo = File.new(local, File::CREAT|File::RDWR)
    hash = Aws.s3i.get(Aws.bucket_name, remote) do |chunk|
      foo.write(chunk)
    end
    foo.close
    hash
  end

  def send_file(remote, local)
    data = File.open(local)
    md5 = md5_item(local)
    headers = {"x-amz-acl" => "public-read"}
    send_verified_data(remote, data, md5, headers)
  end

  def send_verified_data(key, data, md5, headers={})
    begin
      Aws.put_verified_object(key, data, md5, headers={})
    rescue RightAws::AwsError => e
      if e.message =~ /failed MD5 checksum/
        retry if !(RAILS_ENV == 'test')
      else
        raise
      end
    end
  end

  def md5_item(item, incremental=true)
    if incremental
      @md5 = Digest::MD5.new()
      file = File.open(item, 'r')
      file.each_line do |line|
        @md5 << line
      end
    else
      @md5 = Digest::MD5.hexdigest(item)
    end
    @md5.to_s
  end

end
