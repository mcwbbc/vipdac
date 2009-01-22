require File.dirname(__FILE__) + '/../spec_helper'

include ApplicationHelper

describe ApplicationHelper do

  describe "all error messages for" do
    it "should return nil if there are no errors" do
      helper.all_error_messages_for(:job).should == nil
    end

    it "should return the error messages for a model" do
      job = mock_model(Job)
      errors = mock("errors")
      errors.should_receive(:empty?).and_return(false)
      errors.should_receive(:full_messages).and_return(["error message"])
      job.should_receive(:errors).twice.and_return(errors)
      helper.should_receive(:instance_variable_get).with("@job").and_return(job)
      helper.all_error_messages_for(:job).should == "<div class=\"errorExplanation\" id=\"errorExplanation\"><h1>There are problems with your submission</h1><ul><li>error message</li></ul></div>"
    end
  end

  describe "block to partial" do
    it "should render the content inside the block as the body inside the partial" do
      helper.should_receive(:capture).and_return("text")
      helper.should_receive(:render).with(:partial => "partial", :locals => {:body => "text"}).and_return("text")
      helper.should_receive(:concat).with("text").and_return("text")
      helper.block_to_partial("partial", {}).should == "text"
    end
  end

  describe "rounded box" do
    it "should call block to partial with no options" do
      helper.should_receive(:block_to_partial).with("shared/rounded_box", {:css_class=>"css"}).and_return("text")
      helper.rounded_box("css").should == "text"
    end
  end

  describe "flash messages" do
    it "should be nil if we don't have a message with the key" do
      flash[:cheese] = "cheese"
      helper.flash_messages.should == ""
    end

    describe "with a single key" do
      it "should return a single div" do
        flash[:warning] = "warn message"
        helper.flash_messages.should == '<div class="warning">warn message</div>'
      end
    end
    describe "with multiple keys" do
      it "should return mutiple divs" do
        flash[:warning] = "warn message"
        flash[:notice] = "notice message"
        helper.flash_messages.should match(/notice/)
        helper.flash_messages.should match(/warning/)
      end
    end
  end

  describe "message for item" do
    describe "as array" do
      describe "with value" do
        it "should return a formatted string" do
          helper.should_receive(:link_to).with('item', 'another').and_return("item link")
          helper.message_for_item("hello %s", ['item', 'another']).should == "hello item link"
        end
      end
    end
    describe "as other" do
      describe "with value" do
        it "should return a formatted string" do
          helper.message_for_item("hello %s", "there").should == "hello there"
        end
      end
      describe "with nil" do
        it "should return formatting string" do
          helper.message_for_item("hello %s").should == "hello "
        end
      end
    end
  end

  describe "pretty time" do
    it "should display the number with 3 decimal places" do
      pretty_time(12.12345).should == "12.123"
    end

    it "should return 0 for a nil value" do
      pretty_time(nil).should == 0
    end
  end

  describe "page title" do
    it "should return a string" do
      page_title("hello").should eql("<div class='page-title'>hello</div>")
    end
  end

  describe "nice date" do
    it "should return a date for a float" do
      date = mock("date")
      date.should_receive(:instance_of?).with(Float).and_return(true)
      Time.should_receive(:at).with(date).and_return(Time.now)
      nice_date(date).should eql(Time.now.strftime("%m-%d-%Y %I:%M%P"))
    end

    it "should return a date for a date" do
      now = Time.now
      now.should_receive(:instance_of?).with(Float).and_return(false)
      nice_date(now).should eql(Time.now.strftime("%m-%d-%Y %I:%M%P"))
    end
  end

  describe "age in seconds" do
    describe "start and end non zero" do
      it "should return a pretty time for the difference" do
        age_in_seconds(10.0,22.12345).should eql("12.123")
      end
    end
    describe "start, end or both are zero" do
      it "should return not completed for start 0" do
        age_in_seconds(0,1).should eql("Not completed")
      end
      it "should return not completed for end 0" do
        age_in_seconds(1,0).should eql("Not completed")
      end
      it "should return not completed for both 0" do
        age_in_seconds(0,0).should eql("Not completed")
      end
    end
  end

  describe "time in days" do
    it "should return days hours for seconds" do
      seconds = 60 * 60 * 24
      time_in_days(seconds).should eql("1 Day 0 Hours")
    end
  end

  describe "time in hours" do
    it "should return hours and minutes for seconds" do
      seconds = 60 * 60 * 23
      time_in_hours(seconds).should eql("23 Hours 0 Minutes")
    end
  end

  describe "time in minutes" do
    it "should return minutes and seconds for seconds" do
      seconds = 60 * 59
      time_in_minutes(seconds).should eql("59 Minutes 0 Seconds")
    end
  end

  describe "time in seconds" do
    it "should return  seconds for seconds" do
      seconds = 59
      time_in_seconds(seconds).should eql("59.00 Seconds")
    end
  end


  describe "age" do
    describe "zero starting" do
      it "should be not launched for zero ending" do
        age(0,0).should eql("Not launched")
      end

      it "should be not launched for non-zero ending" do
        age(0,10).should eql("Not launched")
      end
    end
    describe "zero ending" do
      it "should be time now for ending" do
        age(0,0).should eql("Not launched")
      end
    end

    describe "seconds" do
      it "should be seconds string" do
        age(1,11).should eql("10.00 Seconds")
      end
    end

    describe "mintues" do
      it "should return minutes string" do
        age(1,71).should eql("1 Minute 10 Seconds")
      end
    end
    
    describe "hours" do
      it "should return hours string" do
        age(1,4201).should eql("1 Hour 10 Minutes")
      end
    end

    describe "days" do
      it "should return days string" do
        age(1,90001).should eql("1 Day 1 Hour")
      end
    end
  end

end
