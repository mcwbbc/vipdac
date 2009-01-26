require File.dirname(__FILE__) + '/../spec_helper'

describe OmssaParameterFile do
  
  before(:each) do
    @omssa_parameter_file = create_omssa_parameter_file
  end

  describe "create" do
    [:name, :database, :enzyme, :missed_cleavages, :precursor_tol, :precursor_search, :product_tol, :product_search, :minimum_charge, :max_charge, :ions].each do |key|
      it "should not create a new instance without '#{key}'" do
        create_omssa_parameter_file(key => nil).should_not be_valid
      end
    end
  end

  describe "import from simpledb" do
    before(:each) do
      @pf = create_omssa_parameter_file
      @spg = mock_model(SearchParameterGroup)
      @spg.should_receive(:reload).and_return(true)
      attributes = mock("hash")
      attributes.should_receive(:keys).and_return(['name', 'database', 'enzyme', 'missed_cleavages', 'precursor_tol', 'product_tol', 'product_search', 'precursor_search', 'minimum_charge', 'max_charge', 'ions', 'modifications'])
      @spg.should_receive(:attributes).and_return(attributes)
      @spg.should_receive(:[]).with('name').and_return(["dGVzdA=="])
      @spg.should_receive(:[]).with('database').and_return(["L3BpcGVsaW5lL2Ricy9odW1hbg=="])
      @spg.should_receive(:[]).with('enzyme').and_return(["MA=="])
      @spg.should_receive(:[]).with('missed_cleavages').and_return(["MA=="])
      @spg.should_receive(:[]).with('precursor_tol').and_return(["Mi41"])
      @spg.should_receive(:[]).with('product_tol').and_return(["MC44"])
      @spg.should_receive(:[]).with('product_search').and_return(["MA=="])
      @spg.should_receive(:[]).with('precursor_search').and_return(["MA=="])
      @spg.should_receive(:[]).with('minimum_charge').and_return(["Mg=="])
      @spg.should_receive(:[]).with('max_charge').and_return(["Mw=="])
      @spg.should_receive(:[]).with('ions').and_return(["MSw0"])
      @spg.should_receive(:[]).with('modifications').and_return(["MSwyLDMsNA=="])
      SearchParameterGroup.should_receive(:all_for).with("omssa").and_return([@spg])
      @pf.should_receive(:[]=).with("name", "test").and_return(true)
      @pf.should_receive(:[]=).with("database", "/pipeline/dbs/human").and_return(true)
      @pf.should_receive(:[]=).with("enzyme", "0").and_return(true)
      @pf.should_receive(:[]=).with("missed_cleavages", "0").and_return(true)
      @pf.should_receive(:[]=).with("precursor_tol", "2.5").and_return(true)
      @pf.should_receive(:[]=).with("product_tol", "0.8").and_return(true)
      @pf.should_receive(:[]=).with("product_search", "0").and_return(true)
      @pf.should_receive(:[]=).with("precursor_search", "0").and_return(true)
      @pf.should_receive(:[]=).with("minimum_charge", "2").and_return(true)
      @pf.should_receive(:[]=).with("max_charge", "3").and_return(true)
      @pf.should_receive(:[]=).with("ions", "1,4").and_return(true)
      @pf.should_receive(:[]=).with("modifications", "1,2,3,4").and_return(true)
      @pf.should_receive(:convert_modifications_to_array).and_return(["1", "2", "3", "4"])
      @pf.should_receive(:modifications=).with(["1", "2", "3", "4"]).and_return(true)
      OmssaParameterFile.should_receive(:new).and_return(@pf)
    end

    it "should create modifications" do
      @pf.should_receive(:save).and_return(true)
      OmssaParameterFile.import_from_simpledb
    end
  end

  describe "convert modifications to array" do
    it "should return nil for a nil value" do
      pf = create_omssa_parameter_file(:modifications => nil)
      pf.convert_modifications_to_array.should == nil
    end

    it "should return an array of values" do
      pf = create_omssa_parameter_file(:modifications => "1,2,3,4")
      pf.convert_modifications_to_array.should == ["1", "2", "3", "4"]
    end
  end

  describe "parameter hash" do
    it "should return a hash with the parameters" do
      pf = create_omssa_parameter_file
      pf.parameter_hash.should == {"name"=>"dGVzdA==", "precursor_tol"=>"Mi41", "enzyme"=>"MA==", "ions"=>"MSw0", "missed_cleavages"=>"MA==", "product_search"=>"MA==", "modifications"=>"MSwyLDMsNA==", "product_tol"=>"MC44", "max_charge"=>"Mw==", "database"=>"aHVtYW4uZmFzdGE=", "minimum_charge"=>"Mg==", "precursor_search"=>"MA=="}
    end
  end

  describe "save to simple db" do
    it "should save the encoded parameters to simpledb" do
      pf = create_omssa_parameter_file
      pf.should_receive(:parameter_hash).and_return({:hash => true})
      SearchParameterGroup.should_receive(:new_for).with({:hash => true}, "omssa").and_return(true)
      pf.save_to_simpledb
    end
  end

  describe "remove from simpledb" do
    it "should remove the record from simpledb" do
      record = mock("simpledb_record")
      record.should_receive(:delete).and_return(true)
      pf = create_omssa_parameter_file
      SearchParameterGroup.should_receive(:for_name_and_searcher).with("test", "omssa").and_return(record)
      pf.remove_from_simpledb
    end

    it "should do nothing if the record isn't in simpledb" do
      pf = create_omssa_parameter_file
      SearchParameterGroup.should_receive(:for_name_and_searcher).with("test", "omssa").and_return(nil)
      pf.remove_from_simpledb
    end
  end


  describe "ions" do
    it "should require 2 valid ions not including ," do
      @omssa_parameter_file.ions = "1"
      @omssa_parameter_file.should have(1).error_on(:ions)
    end

    it "should require 2 valid ions" do
      @omssa_parameter_file.ions = "1,"
      @omssa_parameter_file.should have(1).error_on(:ions)
    end

    it "should require 2 valid ions" do
      @omssa_parameter_file.ions = "1,3"
      @omssa_parameter_file.should be_valid
    end
  end

  describe "convert modification array to string" do
    it "should return nil for a nil array" do
      @omssa_parameter_file.modifications = nil
      @omssa_parameter_file.convert_modifications_to_string.should be_nil
    end
    it "should return a comma deliminated string for the array" do
      @omssa_parameter_file.modifications = [1,2,3,4]
      @omssa_parameter_file.convert_modifications_to_string.should == "1,2,3,4"
    end
  end

  describe "set modifications to string" do
    it "should be nil for a nil array" do
      @omssa_parameter_file.modifications = nil
      @omssa_parameter_file.set_modification_as_string
      @omssa_parameter_file.modifications.should == nil
    end
    it "should be a comma deliminated string for the array" do
      @omssa_parameter_file.modifications = [1,2,3,4]
      @omssa_parameter_file.set_modification_as_string
      @omssa_parameter_file.modifications.should == "1,2,3,4"
    end
  end

  describe "database name" do
    it "should return the database without the fasta extension" do
      @omssa_parameter_file.database_name.should == "human"
    end
  end

  describe ".database_option" do
    it "should return '-d self.database '" do
      @omssa_parameter_file.database_option.should eql("-d /pipeline/dbs/human ")
    end  
  end

  describe  ".enzyme_option" do
    it "should return '-e 0 '"  do
      @omssa_parameter_file.enzyme = 0
      @omssa_parameter_file.enzyme_option.should eql("-e 0 ")
    end
  end

  describe  ".cleavage_option" do
    it "should return return '-v 3 '" do
      @omssa_parameter_file.missed_cleavages = 3
      @omssa_parameter_file.cleavage_option.should eql("-v 3 ")
    end
  end

  describe  ".precursor_tol_option" do
    it "should return '-te 2.5 '" do
      @omssa_parameter_file.precursor_tol = 2.5
      @omssa_parameter_file.precursor_tol_option.should eql("-te 2.5 ")
    end
  end

  describe  ".product_tol_option" do
    it "should return '-to 0.8 '" do
      @omssa_parameter_file.product_tol = 0.8
      @omssa_parameter_file.product_tol_option.should eql("-to 0.8 ")
    end
  end

  describe  ".precursor_search_option" do
    it "should return '-tem 0 '" do
      @omssa_parameter_file.precursor_search = 0
      @omssa_parameter_file.precursor_search_option.should eql("-tem 0 ")
    end
  end

  describe  ".product_search_option" do
    it "should return '-tom 0 '" do
      @omssa_parameter_file.product_search = 0
      @omssa_parameter_file.product_search_option.should eql("-tom 0 ")
    end
  end

  describe  ".minimum_charge_option" do
    it "should return '-zt 2 '" do
      @omssa_parameter_file.minimum_charge = 2
      @omssa_parameter_file.minimum_charge_option.should eql("-zt 2 ")
    end
  end

  describe  ".max_charge_option" do
    it "should return '-zh 3 '" do
      @omssa_parameter_file.max_charge = 3
      @omssa_parameter_file.max_charge_option.should eql("-zh 3 ")
    end
  end

  describe  ".ion_option" do
    it "should return '-i 1,4 '" do
      @omssa_parameter_file.ions = '1,4'
      @omssa_parameter_file.ion_option.should eql("-i 1,4 ")
    end
  end

  describe  ".modification_option" do
    it "should return '-mv 0,3 '" do
      @omssa_parameter_file.modifications = '0,3'
      @omssa_parameter_file.modification_option.should eql("-mv 0,3 ")
    end
    
    it "should return nothing" do
      @omssa_parameter_file.modifications = nil
      @omssa_parameter_file.modification_option.should eql('')
    end
  end

  describe "hidden options" do
    it "should return the string" do
      @omssa_parameter_file.hidden_options.should eql("-tez 1 -zc 1 -zcc 1")
    end
  end

  describe "split ions" do
    it "should return an array of ions" do
      @omssa_parameter_file.ions = "1,2,3,4"
      @omssa_parameter_file.split_ions.should == ["1", "2", "3", "4"]
    end

    it "should return an empty array for a blank string" do
      @omssa_parameter_file.ions = ""
      @omssa_parameter_file.split_ions.should == []
    end

    it "should return an empty array for nil" do
      @omssa_parameter_file.ions = nil
      @omssa_parameter_file.split_ions.should == []
    end
  end

  describe "mods as array" do
    it "should return an array for the string" do
      @omssa_parameter_file.modifications = "1,2,3,4"
      @omssa_parameter_file.mods_as_array.should == ["1","2","3","4"]
    end

    it "should return an nil for blank string" do
      @omssa_parameter_file.modifications = ""
      @omssa_parameter_file.mods_as_array.should == nil
    end

    it "should return an nil for nil string" do
      @omssa_parameter_file.modifications = nil
      @omssa_parameter_file.mods_as_array.should == nil
    end
  end

  describe "ions as array" do
    it "should return an array for the string" do
      @omssa_parameter_file.ions = "1,2,3,4"
      @omssa_parameter_file.ions_as_array.should == ["1","2","3","4"]
    end

    it "should return an nil for blank string" do
      @omssa_parameter_file.ions = ""
      @omssa_parameter_file.ions_as_array.should == nil
    end

    it "should return an nil for nil string" do
      @omssa_parameter_file.ions = nil
      @omssa_parameter_file.ions_as_array.should == nil
    end
  end

  describe "write_file" do
    it "should create a correct file" do
      @omssa_parameter_file = create_omssa_parameter_file
      @omssa_parameter_file.should_receive(:database_option).and_return("-d /pipeline/dbs/human ")
      @omssa_parameter_file.should_receive(:enzyme_option).and_return("-e 0 ")
      @omssa_parameter_file.should_receive(:cleavage_option).and_return("-v 3 ")
      @omssa_parameter_file.should_receive(:precursor_tol_option).and_return("-te 2.5 ")
      @omssa_parameter_file.should_receive(:product_tol_option).and_return("-to 0.8 ")
      @omssa_parameter_file.should_receive(:precursor_search_option).and_return("-tem 0 ")
      @omssa_parameter_file.should_receive(:product_search_option).and_return("-tom 0 ")
      @omssa_parameter_file.should_receive(:minimum_charge_option).and_return("-zt 2 ")
      @omssa_parameter_file.should_receive(:max_charge_option).and_return("-zh 3 ")
      @omssa_parameter_file.should_receive(:ion_option).and_return("-i 1,4 ")
      @omssa_parameter_file.should_receive(:modification_option).and_return("-mv 0,3 ")
      @omssa_parameter_file.should_receive(:hidden_options).and_return("-tez 1 -zc 1 -zcc 1")
      file = mock("file")
      file.should_receive(:puts).and_return(true)
      File.should_receive(:open).with(RAILS_ROOT + '/tmp/parameters.conf', "w").and_yield(file)
      @omssa_parameter_file.write_file(RAILS_ROOT + '/tmp/')
    end
  end

  protected
    def create_omssa_parameter_file(options = {})
      record = OmssaParameterFile.new({
                                       :name => 'test',
                                       :database => 'human.fasta',
                                       :precursor_search => 0,
                                       :product_search => 0,
                                       :ions => '1,4', 
                                       :enzyme => 0, 
                                       :precursor_tol => 2.5, 
                                       :product_tol => 0.8,
                                       :minimum_charge => 2,
                                       :max_charge => 3,
                                       :missed_cleavages => 0,
                                       :modifications => "1,2,3,4"
                                      }.merge(options))
      record
    end
end