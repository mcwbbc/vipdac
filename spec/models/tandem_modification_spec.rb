require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe TandemModification do

  describe "create" do
    [:mass, :amino_acid].each do |key|
      it "should not create a new instance without '#{key}'" do
        create_modification(key => nil).should_not be_valid
      end
    end
  end

  describe "associations" do
    [:tandem_parameter_file].each do |key|
      it "should respond to '#{key}'" do
        create_modification.respond_to?(key).should be_true
      end
    end
  end

  describe "validations" do
    before(:each) do
      @modification = create_modification
    end
    it "should not allow letters for mass" do
      @modification.mass = "a"
      @modification.should_not be_valid
    end
    it "should allow floats for mass" do
      @modification.mass = 1.23
      @modification.should be_valid
    end
    it "should allow integers for mass" do
      @modification.mass = 1
      @modification.should be_valid
    end
  end

  describe "mass_string" do
    before(:each) do
      @mod = create_modification
    end
    it "should return nil if it's a motif AA" do
      @mod.amino_acid = ">[ST!]{P}"
      @mod.mass_string.should == nil
    end

    it "should return a single element" do
      @mod.mass_string.should == "10.0@A"
    end

    it "should return a comma string if there are multiple amino acids" do
      @mod.amino_acid = "ABC"
      @mod.mass_string.should == "10.0@A,10.0@B,10.0@C"
    end

  end

  describe "motif_string" do
    before(:each) do
      @mod = create_modification(:amino_acid => ">[ST!]{P}")
    end

    it "should return nil if it's a normal AA" do
      @mod.amino_acid = "A"
      @mod.motif_string.should == nil
    end

    it "should return motif string" do
      @mod.motif_string.should == "10.0@[ST!]{P}"
    end

  end

  protected
    def create_modification(options = {})
      @tandem_parameter_file = mock_model(TandemParameterFile)
      record = TandemModification.new({ :mass => 10, :amino_acid => "A", :tandem_parameter_file => @tandem_parameter_file}.merge(options))
      record
    end

end
