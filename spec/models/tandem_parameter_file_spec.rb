require File.dirname(__FILE__) + '/../spec_helper'

describe TandemParameterFile do
  before(:each) do
    @parameter_file = create_tandem_parameter_file
  end

  describe "create" do
    [:name, :database].each do |key|
      it "should not create a new instance without '#{key}'" do
        create_tandem_parameter_file(key => nil).should_not be_valid
      end
    end
  end

  describe "associations" do
    [:tandem_modifications].each do |key|
      it "should respond to '#{key}'" do
        create_tandem_parameter_file.respond_to?(key).should be_true
      end
    end
  end

  describe "validations" do
    it "should require a unique name" do
      @parameter_file.save
      duplicate = create_tandem_parameter_file
      duplicate.should_not be_valid
    end

    it "should require at least two ions" do
      @parameter_file.should be_valid
      @parameter_file.b_ion = false
      @parameter_file.should_not be_valid
    end
  end

  describe "persist" do
    it "should send the yamlized parameters to s3" do
      @parameter_file.should_receive(:send_verified_data).with("tandem-parameter-records/209d808516a1c96827605429062f82e3.yml", "--- \nname: jobname\ncreated_at: \nb_ion: true\nenzyme: enzyme\nn_terminal: \nc_ion: \nupdated_at: \nx_ion: \nc_terminal: \ny_ion: true\nmodifications: \ndatabase: human_ipi\nz_ion: \na_ion: \n", "07a54e42b4264a6869c3fdb33e69e936", {}).and_return(true)
      @parameter_file.persist
    end
  end

  describe "delete" do
    it "should remove the data file from s3" do
      Aws.should_receive(:delete_object).with("tandem-parameter-records/209d808516a1c96827605429062f82e3.yml").and_return(true)
      @parameter_file.delete
    end
  end

  describe "import" do
    before(:each) do
      @pf = create_tandem_parameter_file
      @pf.should_receive(:retreive).with("file").and_return("string")
      TandemParameterFile.should_receive(:remote_file_list).with("tandem-parameter-records").and_return(["file"])
      TandemParameterFile.should_receive(:new).and_return(@pf)
    end

    describe "with valid save" do
      before(:each) do
        @pf.should_receive(:save).and_return(true)
      end

      it "should create modifications" do
        @hash = {"modifications" => [{"mass"=>"12.0", "amino_acid"=>"abc"}, {"mass"=>"-2.0", "amino_acid"=>"def"}]}
        YAML.should_receive(:load).with("string").and_return(@hash)
        @pf.should_receive(:create_modifications).with([{"mass"=>"12.0", "amino_acid"=>"abc"}, {"mass"=>"-2.0", "amino_acid"=>"def"}]).and_return(true)
        TandemParameterFile.import
      end

      it "should not create modifications" do
        @hash = {"modifications" => nil}
        YAML.should_receive(:load).with("string").and_return(@hash)
        TandemParameterFile.import
      end
    end

    describe "without save" do
      it "should not create modifications" do
        @hash = {"modifications" => nil}
        YAML.should_receive(:load).with("string").and_return(@hash)
        @pf.should_receive(:save).and_return(false)
        TandemParameterFile.import
      end
    end
  end

  describe "create modifications" do
    it "should create a tandem modification for each member of the array" do
      pf = create_tandem_parameter_file
      tmods = mock("array")
      tmods.should_receive(:create).with(:mass => "1.0", :amino_acid => "abc").and_return(true)
      tmods.should_receive(:create).with(:mass => "2.0", :amino_acid => "def").and_return(true)
      pf.should_receive(:tandem_modifications).twice.and_return(tmods)
      array = [{"mass"=>"1.0", "amino_acid"=>"abc"}, {"mass"=>"2.0", "amino_acid"=>"def"}]
      pf.create_modifications(array)
    end
  end

  describe "setup ions" do
    it "should set the model values based on the supplied yaml string" do
      pf = create_tandem_parameter_file
      yaml = "--- \nb_ion: true\nx_ion: false\nc_ion: false\ny_ion: true\nz_ion: false\na_ion: false\n"
      pf.setup_ions(yaml)
      pf.a_ion.should be_false
      pf.b_ion.should be_true
      pf.c_ion.should be_false
      pf.x_ion.should be_false
      pf.y_ion.should be_true
      pf.z_ion.should be_false
    end
  end

  describe "parameter hash" do
    it "should return a hash with the parameters" do
      pf = create_tandem_parameter_file
      pf.parameter_hash.should == {"name"=>"jobname", "created_at"=>nil, "b_ion"=>true, "enzyme"=>"enzyme", "n_terminal"=>nil, "c_ion"=>nil, "updated_at"=>nil, "x_ion"=>nil, "c_terminal"=>nil, "y_ion"=>true, "modifications"=>nil, "database"=>"human_ipi", "z_ion"=>nil, "a_ion"=>nil}
    end

    it "should return an array of modifications" do
      pf = create_tandem_parameter_file
      m1 = mock_model(TandemModification, :mass => 12.0, :amino_acid => "abc")
      m2 = mock_model(TandemModification, :mass => -2.0, :amino_acid => "def")
      modifications = [m1, m2]
      pf.should_receive(:tandem_modifications).twice.and_return(modifications)
      pf.parameter_hash.should == {"name"=>"jobname", "created_at"=>nil, "b_ion"=>true, "enzyme"=>"enzyme", "n_terminal"=>nil, "c_ion"=>nil, "updated_at"=>nil, "x_ion"=>nil, "c_terminal"=>nil, "y_ion"=>true, "modifications"=>[{"mass"=>"12.0", "amino_acid"=>"abc"}, {"mass"=>"-2.0", "amino_acid"=>"def"}], "database"=>"human_ipi", "z_ion"=>nil, "a_ion"=>nil}
    end
  end

  describe "modifications array" do
    it "should return a yaml string for the modifictions in the parameter file" do
      m1 = mock_model(TandemModification, :mass => 12.0, :amino_acid => "abc")
      m2 = mock_model(TandemModification, :mass => -2.0, :amino_acid => "def")
      modifications = [m1, m2]
      pf = create_tandem_parameter_file
      pf.should_receive(:tandem_modifications).twice.and_return(modifications)
      pf.modifications_array.should == [{"mass"=>"12.0", "amino_acid"=>"abc"}, {"mass"=>"-2.0", "amino_acid"=>"def"}]
    end

    it "should return a yaml string for the modifictions in the parameter file" do
      pf = create_tandem_parameter_file
      pf.should_receive(:tandem_modifications).and_return([])
      pf.modifications_array.should == nil
    end
  end

  describe "ions" do
    it "should return [] for no selected ions" do
      @parameter_file.b_ion = false
      @parameter_file.y_ion = false
      @parameter_file.ions.should == []
    end

    it "should return [true,true] for 2 selected ions" do
      @parameter_file.b_ion = true
      @parameter_file.ions.should == [true, true]
    end
  end
  
  describe "ion_names" do
    it "should return '' for no selected ions" do
      @parameter_file.b_ion = false
      @parameter_file.y_ion = false
      @parameter_file.ion_names.should == ''
    end

    it "should return 'B-ions Y-ions' for 2 selected ions" do
      @parameter_file.ion_names.should == "B-ions Y-ions"
    end
  end

  describe "ion_xml" do
    it "should not have a yes for all ions false" do
      @parameter_file = create_tandem_parameter_file(:a_ion => false, :b_ion => false, :c_ion => false, :x_ion => false, :y_ion => false, :z_ion => false)
      @parameter_file.ion_xml.should_not match(/yes<\/note>/)
    end
    it "should not have a no for all ions true" do
      @parameter_file = create_tandem_parameter_file(:a_ion => true, :b_ion => true, :c_ion => true, :x_ion => true, :y_ion => true, :z_ion => true)
      @parameter_file.ion_xml.should_not match(/no<\/note>/)
    end
  end

  describe "mass_xml" do
    it "should return empty string for no modifications" do
      @parameter_file.mass_xml.should == ""
    end

    it "should return empty string for no mass modifications" do
      @mod1 = mock_model(TandemModification)
      @mod1.should_receive(:mass_string).once.and_return(nil)
      @parameter_file.should_receive(:tandem_modifications).twice.and_return([@mod1])
      @parameter_file.mass_xml.should == ""
    end

    it "should return return the mass string for a single modification" do
      @mod1 = mock_model(TandemModification)
      @mod1.should_receive(:mass_string).twice.and_return("10.0@A")
      @parameter_file.should_receive(:tandem_modifications).twice.and_return([@mod1])
      @parameter_file.mass_xml.should match(/10.0@A/)
    end

    it "should return return the mass string for multiple modifications" do
      @mod1 = mock_model(TandemModification)
      @mod1.should_receive(:mass_string).twice.and_return("10.0@A")
      @mod2 = mock_model(TandemModification)
      @mod2.should_receive(:mass_string).twice.and_return("20.0@B")
      @parameter_file.should_receive(:tandem_modifications).twice.and_return([@mod1, @mod2])
      @parameter_file.mass_xml.should match(/10.0@A,20.0@B/)
    end

    it "should return return the mass string for multiple modifications excluding nil values" do
      @mod1 = mock_model(TandemModification)
      @mod1.should_receive(:mass_string).twice.and_return("10.0@A")
      @mod2 = mock_model(TandemModification)
      @mod2.should_receive(:mass_string).once.and_return(nil)
      @mod3 = mock_model(TandemModification)
      @mod3.should_receive(:mass_string).twice.and_return("20.0@B")
      @parameter_file.should_receive(:tandem_modifications).twice.and_return([@mod1, @mod2, @mod3])
      @parameter_file.mass_xml.should match(/10.0@A,20.0@B/)
    end
  end

  describe "motif_xml" do
    it "should return empty string for no modifications" do
      @parameter_file.motif_xml.should == ""
    end

    it "should return empty string for no motif modifications" do
      @mod1 = mock_model(TandemModification)
      @mod1.should_receive(:motif_string).once.and_return(nil)
      @parameter_file.should_receive(:tandem_modifications).twice.and_return([@mod1])
      @parameter_file.motif_xml.should == ""
    end

    it "should return return the motif string for a single modification" do
      @mod1 = mock_model(TandemModification)
      @mod1.should_receive(:motif_string).twice.and_return("10.0@[ST!]{P}")
      @parameter_file.should_receive(:tandem_modifications).twice.and_return([@mod1])
      @parameter_file.motif_xml.should == %Q(<note type="input" label="residue, potential modification motif">10.0@[ST!]{P}</note>)
    end

    it "should return return the motif string for multiple modifications" do
      @mod1 = mock_model(TandemModification)
      @mod1.should_receive(:motif_string).twice.and_return("10.0@[ST!]{P}")
      @mod2 = mock_model(TandemModification)
      @mod2.should_receive(:motif_string).twice.and_return("20.0@[SX!]{X}")
      @parameter_file.should_receive(:tandem_modifications).twice.and_return([@mod1, @mod2])
      @parameter_file.motif_xml.should == %Q(<note type="input" label="residue, potential modification motif">10.0@[ST!]{P},20.0@[SX!]{X}</note>)
    end

    it "should return return the motif string for multiple modifications excluding nil values" do
      @mod1 = mock_model(TandemModification)
      @mod1.should_receive(:motif_string).twice.and_return("10.0@[ST!]{P}")
      @mod2 = mock_model(TandemModification)
      @mod2.should_receive(:motif_string).once.and_return(nil)
      @mod3 = mock_model(TandemModification)
      @mod3.should_receive(:motif_string).twice.and_return("20.0@[SX!]{X}")
      @parameter_file.should_receive(:tandem_modifications).twice.and_return([@mod1, @mod2, @mod3])
      @parameter_file.motif_xml.should == %Q(<note type="input" label="residue, potential modification motif">10.0@[ST!]{P},20.0@[SX!]{X}</note>)
    end
  end

  describe "string functions" do
    it "should return a valid xml string for taxon_xml" do
      @parameter_file.taxon_xml.should match(/taxon">human_ipi/)
    end
    it "should return a valid xml string for enzyme_xml" do
      @parameter_file.enzyme = "enz"
      @parameter_file.enzyme_xml.should match(/cleavage site">enz/)
    end
    it "should return a valid xml string for n_terminal_xml" do
      @parameter_file.n_terminal = "12"
      @parameter_file.n_terminal_xml.should match(/N-terminal mass change">12/)
    end
    it "should return a valid xml string for c_terminal_xml" do
      @parameter_file.c_terminal = "1234"
      @parameter_file.c_terminal_xml.should match(/C-terminal mass change">1234/)
    end
  end

  describe "writing the parameter file" do
    it "should create a file with the name" do
      @file = mock("file")
      @file.should_receive(:puts).and_return(true)
      File.should_receive(:open).with("jobdir/parameters.conf", "w").once.and_yield(@file)
      @parameter_file.write_file("jobdir/")
    end
  end

  describe "page" do
    it "should call paginate" do
      TandemParameterFile.should_receive(:paginate).with({:page => 2, :order => 'name', :per_page => 20}).and_return(true)
      TandemParameterFile.page(2,20)
    end
  end

  describe "modification attributes" do
    before(:each) do
      @array = ["one", "two"]
    end

    it "should respond to the request" do
      @parameter_file.should_receive(:modification_attributes=).with(@array).and_return(true)
      @parameter_file.modification_attributes=(@array)
    end

    it "should build tandem modifications for each attribute" do
      tandem_modifications = mock("modifications")
      tandem_modifications.should_receive(:build).with("one").and_return(true)
      tandem_modifications.should_receive(:build).with("two").and_return(true)
      @parameter_file.should_receive(:tandem_modifications).twice.and_return(tandem_modifications)
      @parameter_file.modification_attributes=(@array)
    end
  end

  protected
    def create_tandem_parameter_file(options = {})
      record = TandemParameterFile.new({ :name => "jobname", :database => "human_ipi", :enzyme => "enzyme", :b_ion => true, :y_ion => true }.merge(options))
      record
    end

end
