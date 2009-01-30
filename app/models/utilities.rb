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

  def extract_etag(hash)
    begin
      hash[:headers]['etag'].gsub(/\"/, '')
    rescue StandardError
      ''
    end
  end

  def remote_file_list(prefix)
    Aws.s3i.incrementally_list_bucket(Aws.bucket_name, { 'prefix' => "#{prefix}" }) do |file|
      @list = file[:contents].map {|content| content[:key] }
    end
    @list
  end

  def download_file(local, remote)
    begin
      File.open(local, File::CREAT|File::RDWR) do |file|
        @hash = Aws.s3i.get(Aws.bucket_name, remote) do |chunk|
          file.write(chunk)
        end
      end
    end while (fail = (extract_etag(@hash) != md5_item(local)))
    !fail
  end

  def send_file(remote, local)
    md5 = md5_item(local)
    headers = {"x-amz-acl" => "public-read"}
    File.open(local) do |data|
      send_verified_data(remote, data, md5, headers)
    end
  end

  def send_verified_data(key, data, md5, headers={})
    begin
      Aws.put_verified_object(key, data, md5, headers)
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
