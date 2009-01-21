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

  describe ".database_option" do
    it "should return '-d self.database '" do
      @omssa_parameter_file.database_option.should eql("-d #{@omssa_parameter_file.database} ")
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
                                       :database => '/pipeline/dbs/human',
                                       :precursor_search => 0,
                                       :product_search => 0,
                                       :ions => '1,4', 
                                       :enzyme => 0, 
                                       :precursor_tol => 2.5, 
                                       :product_tol => 0.8,
                                       :minimum_charge => 2,
                                       :max_charge => 3,
                                       :missed_cleavages => 0
                                      }.merge(options))
      record
    end
end