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

  describe "persist" do
    it "should send the yamlized parameters to s3" do
      @omssa_parameter_file.should_receive(:send_verified_data).with("omssa-parameter-records/098f6bcd4621d373cade4e832627b4f6.yml", "--- \nprecursor_tol: 2.5\nname: test\nions: \"1,4\"\nenzyme: 0\nmissed_cleavages: 0\nproduct_search: 0\nproduct_tol: 0.8\nmodifications: \"1,2,3,4\"\nmax_charge: 3\nprecursor_search: 0\nminimum_charge: 2\ndatabase: human.fasta\n", "d6505a152d7a47ff3ed037319f455cfa", {}).and_return(true)
      @omssa_parameter_file.persist
    end
  end

  describe "delete" do
    it "should remove the data file from s3" do
      Aws.should_receive(:delete_object).with("omssa-parameter-records/098f6bcd4621d373cade4e832627b4f6.yml").and_return(true)
      @omssa_parameter_file.delete
    end
  end

  describe "import" do
    it "should load all the available parameter files into the local database" do
      @pf = create_omssa_parameter_file
      @pf.should_receive(:convert_modifications_to_array).and_return([1,2])
      hash = {}
      @pf.should_receive(:retreive).with("file").and_return("string")
      YAML.should_receive(:load).with("string").and_return(hash)
      OmssaParameterFile.should_receive(:remote_file_list).with("omssa-parameter-records").and_return(["file"])
      OmssaParameterFile.should_receive(:new).and_return(@pf)
      @pf.should_receive(:save).and_return(true)
      OmssaParameterFile.import
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

  describe "stats hash" do
    it "should return a stats hash with the name md5'd" do
      pf = create_omssa_parameter_file
      pf.stats_hash.should == {"name"=>"098f6bcd4621d373cade4e832627b4f6", "precursor_tol"=>2.5, "enzyme"=>0, "ions"=>"1,4", "missed_cleavages"=>0, "product_search"=>0, "modifications"=>"1,2,3,4", "product_tol"=>0.8, "max_charge"=>3, "database"=>"human.fasta", "minimum_charge"=>2, "precursor_search"=>0}
    end
  end

  describe "parameter hash" do
    it "should return a hash with the parameters" do
      pf = create_omssa_parameter_file
      pf.parameter_hash.should == {"name"=>"test", "precursor_tol"=>2.5, "enzyme"=>0, "ions"=>"1,4", "missed_cleavages"=>0, "product_search"=>0, "modifications"=>"1,2,3,4", "product_tol"=>0.8, "max_charge"=>3, "database"=>"human.fasta", "minimum_charge"=>2, "precursor_search"=>0}
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
      file = mock("file")
      file.should_receive(:puts).with("-d /pipeline/dbs/human -e 0 -v 0 -te 2.5 -to 0.8 -tem 0 -tom 0 -zt 2 -zh 3 -i 1,4 -mv 1,2,3,4 -tez 1 -zc 1 -zcc 1").and_return(true)
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