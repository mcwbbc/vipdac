require File.dirname(__FILE__) + '/../spec_helper'

describe OmssaOption do

  before(:each) do
    OmssaOption.modifications = nil
    OmssaOption.enzymes = nil
    OmssaOption.ions = nil
    OmssaOption.searches = nil
    OmssaOption.options_file = nil
    OmssaOption.database_file = nil
  end

  describe "generate hash" do
    it "should take a regex and generate the proper hash" do
      @array = ["<mod id='23'>2-amino-3-oxo-butanoic acid T</mod>","<mod id='182'>Asparagine HexNAc</mod>"]
      OmssaOption.should_receive(:options_file).and_return(@array)
      OmssaOption.generate_hash(/<mod id='(\d+)'>(.+?)</).should == {'2-amino-3-oxo-butanoic acid T' => "23", 'Asparagine HexNAc' => "182"}
    end
  end

  describe "options_file array" do
    describe "success" do
      it "should load the options file into an array" do
        @array = ["hello", "there"]
        File.should_receive(:readlines).with(/omssa_config/).and_return(@array)
        OmssaOption.options_file.should == @array
      end
    end

    describe "error" do
      it "should return an empty array" do
        File.should_receive(:readlines).with(/omssa_config/).and_raise("exception")
        OmssaOption.options_file.should == []
      end
    end
  end

  describe "database file array" do
    describe "success" do
      it "should load the options file into an array" do
        @array = ["hello", "there"]
        File.should_receive(:readlines).with(/tandem_config/).and_return(@array)
        OmssaOption.database_file.should == @array
      end
    end

    describe "error" do
      it "should return an empty array" do
        File.should_receive(:readlines).with(/tandem_config/).and_raise("exception")
        OmssaOption.database_file.should == []
      end
    end
  end


  describe "setting options" do
    describe "modifications" do
      describe "on success" do
        it "should return a hash" do
          @array = ["<mod id='23'>2-amino-3-oxo-butanoic acid T</mod>","<mod id='182'>Asparagine HexNAc</mod>"]
          File.should_receive(:readlines).with(/omssa_config/).and_return(@array)
          OmssaOption.modifications.should == {'2-amino-3-oxo-butanoic acid T' => "23", 'Asparagine HexNAc' => "182"}
        end
      end

      describe "on error" do
        it "should return an empty hash" do
          File.should_receive(:readlines).with(/omssa_config/).and_raise("exception")
          OmssaOption.modifications.should == {}
        end
      end
    end

    describe "enzymes" do
      describe "on success" do
        it "should return a hash" do
          @array = ["<enzyme id='0'>Trypsin</enzyme>","<enzyme id='1'>Arg-C</enzyme>"]
          File.should_receive(:readlines).with(/omssa_config/).and_return(@array)
          OmssaOption.enzymes.should == {'Trypsin' => "0", 'Arg-C' => "1"}
        end
      end

      describe "on error" do
        it "should return an empty hash" do
          File.should_receive(:readlines).with(/omssa_config/).and_raise("exception")
          OmssaOption.enzymes.should == {}
        end
      end
    end

    describe "ions" do
      describe "on success" do
        it "should return a hash" do
          @array = ["<ion id='0'>A-ions</ion>", "<ion id='1'>B-ions</ion>"]
          File.should_receive(:readlines).with(/omssa_config/).and_return(@array)
          OmssaOption.ions.should == {'A-ions' => "0", 'B-ions' => "1"}
        end
      end

      describe "on error" do
        it "should return an empty hash" do
          File.should_receive(:readlines).with(/omssa_config/).and_raise("exception")
          OmssaOption.ions.should == {}
        end
      end
    end

    describe "searches" do
      describe "on success" do
        it "should return a hash" do
          @array = ["<search id='0'>monoisotopic</search>", "<search id='1'>average</search>"]
          File.should_receive(:readlines).with(/omssa_config/).and_return(@array)
          OmssaOption.searches.should == {'monoisotopic' => "0", 'average' => "1"}
        end
      end

      describe "on error" do
        it "should return an empty hash" do
          File.should_receive(:readlines).with(/omssa_config/).and_raise("exception")
          OmssaOption.searches.should == {}
        end
      end
    end

  end

  
  protected
    def create_omssa_option(options = {})
      record = OmssaOption.new({  }.merge(options))
      record
    end

end
