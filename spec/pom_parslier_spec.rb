require 'spec_helper'

describe PomParslier do
  let(:date_line) { "2/14/2014" } 
  let(:separator) { "--" }
  let(:break_line) { "BREAK 1" }
  let(:escape_line)  {"//--"}

  let(:task_basic) { "19.5 Watch an episode of The Wire XX"}
  let(:task_with_tag) { "13.5 $R Fold laundry and put it away XX"}
  let(:task_with_category) { "0.5 Tree Climbing: go to the park and climb a tree X"}
  let(:task_with_soft_time_estimate) { "6 Start implementing business logic at getrich.io (X)(X)(X)X"}
  let(:task_with_hard_time_limit) {"9.5 Eat as much food as possible [X]XX"}

  let(:basic_raw_data) {  }
  def basic_file(*args)
    puts date_line
    puts task_basic
    args ||= [date_line, task_basic]
  end 

  let(:parser) { PomParslier.new(fake_file) }

  context "#initialize" do
    it "initializes an instance of class PomParslier" do
      parser.should be_an_instance_of PomParslier
    end

    it "takes an array of lines and stores them in #raw_data" do
      parser.raw_data.should eq [date_line, task_basic]
    end

  end
end
