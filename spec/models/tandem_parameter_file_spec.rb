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
      @parameter_file.should_not be_valid
      @parameter_file.b_ion = true
      @parameter_file.should be_valid
    end
  end

  describe "import from simple db" do
    before(:each) do
      @pf = create_tandem_parameter_file
      @spg = mock_model(SearchParameterGroup)
      @spg.should_receive(:reload).and_return(true)
      @spg.should_receive(:[]).with('name').and_return(["ZGVtbw=="])
      @spg.should_receive(:[]).with('database').and_return(["aHVtYW5faXBp"])
      @spg.should_receive(:[]).with('enzyme').and_return(["W1hdfFtYXQ=="])
      @spg.should_receive(:[]).with('n_terminal').and_return(nil)
      @spg.should_receive(:[]).with('c_terminal').and_return(nil)
      @spg.should_receive(:[]).with('ions').and_return(["LS0tIApiX2lvbjogdHJ1ZQp4X2lvbjogZmFsc2UKY19pb246IGZhbHNlCnlfaW9uOiB0cnVlCnpfaW9uOiBmYWxzZQphX2lvbjogZmFsc2UK"])
      SearchParameterGroup.should_receive(:all_for).with("xtandem").and_return([@spg])
      @pf.should_receive(:name=).with("demo").and_return(true)
      @pf.should_receive(:database=).with("human_ipi").and_return(true)
      @pf.should_receive(:enzyme=).with("[X]|[X]").and_return(true)
      @pf.should_receive(:n_terminal=).with(nil).and_return(true)
      @pf.should_receive(:c_terminal=).with(nil).and_return(true)
      @pf.should_receive(:setup_ions).with("--- \nb_ion: true\nx_ion: false\nc_ion: false\ny_ion: true\nz_ion: false\na_ion: false\n").and_return(true)
      TandemParameterFile.should_receive(:new).and_return(@pf)
    end

    describe "with valid save" do
      it "should create modifications" do
        @pf.should_receive(:save).and_return(true)
        @spg.should_receive(:[]).with('modifications').and_return(nil)
        @pf.should_receive(:create_modifications).with(nil).and_return(true)
        TandemParameterFile.import_from_simpledb
      end
    end

    describe "without save" do
      it "should not create modifications" do
        @pf.should_receive(:save).and_return(false)
        TandemParameterFile.import_from_simpledb
      end
    end
  end

  describe "create modifications" do
    it "should parse the yaml string and create a tandem modification for each member of the array" do
      pf = create_tandem_parameter_file
      tmods = mock("array")
      tmods.should_receive(:create).with(:mass => "1.0", :amino_acid => "abc").and_return(true)
      tmods.should_receive(:create).with(:mass => "2.0", :amino_acid => "def").and_return(true)
      pf.should_receive(:tandem_modifications).twice.and_return(tmods)
      yaml = '--- \n- mass: "1.0"\n  amino_acid: abc\n- mass: "2.0"\n  amino_acid: def\n'
      array = [{"mass"=>"1.0", "amino_acid"=>"abc"}, {"mass"=>"2.0", "amino_acid"=>"def"}]
      YAML.should_receive(:load).with(yaml).and_return(array)
      pf.create_modifications(yaml)
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

  describe "remove from simpledb" do
    it "should remove the record from simpledb" do
      record = mock("simpledb_record")
      record.should_receive(:delete).and_return(true)
      pf = create_tandem_parameter_file
      SearchParameterGroup.should_receive(:for_name_and_searcher).with("jobname", "xtandem").and_return(record)
      pf.remove_from_simpledb
    end

    it "should do nothing if the record isn't in simpledb" do
      pf = create_tandem_parameter_file
      SearchParameterGroup.should_receive(:for_name_and_searcher).with("jobname", "xtandem").and_return(nil)
      pf.remove_from_simpledb
    end
  end

  describe "parameter hash" do
    it "should return a hash with the parameters" do
      pf = create_tandem_parameter_file
      pf.parameter_hash.should == {"name"=>"am9ibmFtZQ==", "database"=>"aHVtYW5faXBp", "ions"=>"LS0tIApiX2lvbjogCnhfaW9uOiAKY19pb246IAp5X2lvbjogCnpfaW9uOiAKYV9pb246IHRydWUK", "n_terminal"=>"", "enzyme"=>"ZW56eW1l", "c_terminal"=>"", "modifications"=>nil}
    end
  end

  describe "save to simple db" do
    it "should save the encoded parameters to simpledb" do
      pf = create_tandem_parameter_file
      pf.should_receive(:parameter_hash).and_return({:hash => true})
      SearchParameterGroup.should_receive(:new_for).with({:hash => true}, "xtandem").and_return(true)
      pf.save_to_simpledb
    end
  end

  describe "yaml modifications" do
    it "should return a yaml string for the modifictions in the parameter file" do
      m1 = mock_model(TandemModification, :mass => 12.0, :amino_acid => "abc")
      m2 = mock_model(TandemModification, :mass => -2.0, :amino_acid => "def")
      modifications = [m1, m2]
      pf = create_tandem_parameter_file
      pf.should_receive(:tandem_modifications).twice.and_return(modifications)
      pf.yaml_modifications.should == "--- \n- mass: \"12.0\"\n  amino_acid: abc\n- mass: \"-2.0\"\n  amino_acid: def\n"
    end

    it "should return a yaml string for the modifictions in the parameter file" do
      pf = create_tandem_parameter_file
      pf.should_receive(:tandem_modifications).and_return([])
      pf.yaml_modifications.should == nil
    end
  end

  describe "yaml ions" do
    it "should return a yaml string for the ions in the parameter file" do
      pf = create_tandem_parameter_file
      pf.yaml_ions.should == "--- \nb_ion: \nx_ion: \nc_ion: \ny_ion: \nz_ion: \na_ion: true\n"
    end
  end

  describe "ions" do
    it "should return [] for no selected ions" do
      @parameter_file.a_ion = false
      @parameter_file.ions.should == []
    end

    it "should return [true,true] for 2 selected ions" do
      @parameter_file.b_ion = true
      @parameter_file.ions.should == [true, true]
    end
  end
  
  describe "ion_names" do
    it "should return '' for no selected ions" do
      @parameter_file.a_ion = false
      @parameter_file.ion_names.should == ''
    end

    it "should return 'A-ions B-ions' for 2 selected ions" do
      @parameter_file.b_ion = true
      @parameter_file.ion_names.should == "A-ions B-ions"
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
      record = TandemParameterFile.new({ :name => "jobname", :database => "human_ipi", :enzyme => "enzyme", :a_ion => true }.merge(options))
      record
    end

end
