require 'spec_helper'

describe HashMagic do
  let(:hash) { { "dog" => 12 }}
  context "#initialize" do
    magic = HashMagic.new(hash)
    magic.should be_an_instance_of String
  end
  context "#match_hierarchy" do 
    it "takes a flat hash and matches its keys to a nested structure"

  end
end