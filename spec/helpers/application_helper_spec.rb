require File.dirname(__FILE__) + '/../spec_helper'

include ApplicationHelper

describe ApplicationHelper do
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
