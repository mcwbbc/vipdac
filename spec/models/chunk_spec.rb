require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Chunk do
  before(:each) do
    @chunk = create_chunk
  end

  describe "create" do
    [:job_id, :chunk_key].each do |key|
      it "should not create a new instance without '#{key}'" do
        create_chunk(key => nil).should_not be_valid
      end
    end
  end

  describe "associations" do
    [:job].each do |key|
      it "should respond to '#{key}'" do
        create_chunk.respond_to?(key).should be_true
      end
    end
  end

  describe "named scopes" do
    it "should have a 'pending' named scope where started_at is zero" do
      @chunk.should have_named_scope(:pending).finding(:conditions => ['started_at = ?', 0])
    end

    it "should have a 'pending' named scope where started_at is > 0 and finished_at is zero" do
      @chunk.should have_named_scope(:working).finding(:conditions => ['started_at > ? AND finished_at = ?', 0, 0])
    end

    it "should have a 'pending' named scope where started_at and finished_at are > 0" do
      @chunk.should have_named_scope(:complete).finding(:conditions => ['started_at > ? AND finished_at > ?', 0, 0])
    end

    it "should have a 'incomplete' named scope where finished_at = 0" do
      @chunk.should have_named_scope(:incomplete).finding(:conditions => ['finished_at = ?', 0])
    end
  end

  describe "status" do
    it "should be 'Created' if we haven't started" do
      @chunk.should_receive(:started_at).and_return(0)
      @chunk.status.should == "Created"
    end
    it "should be 'Created' if we haven't finished" do
      @chunk.should_receive(:started_at).and_return(1)
      @chunk.should_receive(:finished_at).and_return(0)
      @chunk.status.should == "Working"
    end
    it "should be 'Complete' if we we're done" do
      @chunk.should_receive(:started_at).and_return(1)
      @chunk.should_receive(:finished_at).and_return(1)
      @chunk.status.should == "Complete"
    end
  end

  describe "finished?" do
    it "should be finsihed if finished is non zero" do
      @chunk.should_receive(:finished_at).and_return(1)
      @chunk.finished?.should be_true
    end
    it "should not be finsihed if finished is zero" do
      @chunk.should_receive(:finished_at).and_return(0)
      @chunk.finished?.should be_false
    end
  end

  describe "send the process message" do
    it "should send an aws message to process the chunk" do
      hash = { :type => PROCESS,
               :chunk_count => 1,
               :bytes => 10,
               :sendtime => 1.0,
               :chunk_key => "key",
               :job_id => 12,
               :hash_key => 'hash_key',
               :searcher => "omssa",
               :search_database => "search_database",
               :filename => "filename",
               :bucket_name => "bucket",
               :parameter_filename => "parameter_filename"
             }

      job = mock_model(Job)
      job.should_receive(:id).and_return(12)
      job.should_receive(:hash_key).and_return('hash_key')
      job.should_receive(:priority).and_return(100)
      job.should_receive(:searcher).and_return("omssa")
      job.should_receive(:search_database).and_return("search_database")
      @chunk = create_chunk(:chunk_count => 1, :bytes => 10, :sent_at => 1.0, :filename => "filename", :parameter_filename => "parameter_filename")
      @chunk.should_receive(:job).exactly(5).times.and_return(job)
      MessageQueue.should_receive(:put).with(:name => 'node', :message => hash.to_yaml, :priority => 100, :ttr => 1200).and_return(true)
      Aws.should_receive(:bucket_name).and_return("bucket")
      @chunk.send_process_message.should be_true
    end
  end

  describe "pretty_filename should spilt string on /" do

    it "should return nil for single string" do
      @chunk.filename = "/"
      @chunk.pretty_filename.should == ""
    end

    it "should return last with one /" do
      @chunk.filename = "/last"
      @chunk.pretty_filename.should == "last"
    end

    it "should return last element" do
      @chunk.filename = "/hello/there/last"
      @chunk.pretty_filename.should == "last"
    end
  end

  describe "find for node" do
    it "should return an array of chunks for instance with a limit" do
      Chunk.should_receive(:find).with(:all, {:limit=>10, :conditions=>["instance_id LIKE ?", "id%"], :order=>"updated_at DESC"}).and_return(["chunk"])
      Chunk.find_for_node("id", 10).should == ["chunk"]
    end
  end

  describe "reporter chunk" do
    before(:each) do
      @report = {:chunk_key => "key", :job_id => 1234, :instance_id => "instance-id", :filename => "filename", :parameter_filename => "parameter_filename",
                 :bytes => "10", :chunk_count => 2, :sendtime => 1.0, :starttime => 2.0, :finishtime => 3.0}
    end
    
    describe "new chunk" do
      it "should create a new chunk" do
        new_chunk = create_chunk
        Node.should_receive(:size_of_node).with("instance-id").and_return("c1.medium")
        Chunk.should_receive(:find_or_create_by_chunk_key).with("key").and_return(new_chunk)
        chunk = Chunk.reporter_chunk(@report)
        chunk.finished_at.should == 3.0
      end
    end

    describe "old chunk" do
      it "should load the chunk from the db" do
        db_chunk = create_chunk
        db_chunk.finished_at = 2.5
        Node.should_receive(:size_of_node).with("instance-id").and_return("c1.medium")
        Chunk.should_receive(:find_or_create_by_chunk_key).with("key").and_return(db_chunk)
        chunk = Chunk.reporter_chunk(@report)
        chunk.finished_at.should == 2.5
      end
    end
  end

  describe "stats hash" do
    it "should return a hash of the statistical data" do
      chunk = create_chunk(:instance_size => 'c1.medium', :instance_id => "i-1234-1111", :bytes => 1234, :sent_at => 1.0, :started_at => 2.0, :finished_at => 3.0)
      chunk.stats_hash.should == {"bytes"=>1234, "finished_at"=>3.0, "instance_id"=>"i-1234-1111", "instance_size"=>"c1.medium", "sent_at"=>1.0, "started_at"=>2.0}
    end
  end

  protected
    def create_chunk(options = {})
      record = Chunk.new({ :job_id => 12, :chunk_key => "key" }.merge(options))
      record
    end

end
