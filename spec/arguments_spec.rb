require "mothership"
require "./helpers"

describe Mothership::Parser do
  describe "arguments" do
    describe "normal" do
      it "is declared as an input" do
        command(:foo => { :argument => true }) do |c|
          inputs(c, "bar").should == { :foo => "bar" }
        end
      end

      it "can be passed as a flag" do
        command(:foo => { :argument => true }) do |c|
          inputs(c, "--foo", "bar").should == { :foo => "bar" }
        end
      end

      it "is parsed in the order of definition" do
        command([
            [:foo, { :argument => true }],
            [:bar, { :argument => true }]]) do |c|
          inputs(c, "fizz", "buzz").should ==
            { :foo => "fizz", :bar => "buzz" }
        end

        command([
            [:bar, { :argument => true }],
            [:foo, { :argument => true }]]) do |c|
          inputs(c, "fizz", "buzz").should ==
            { :foo => "buzz", :bar => "fizz" }
        end
      end
    end

    describe "as flags" do
      it "assigns as the value if given" do
        command(:foo => { :argument => true }) do |c|
          inputs(c, "--foo", "bar").should == { :foo => "bar" }
        end
      end

      it "assigns as an empty string if just name is given" do
        command(:foo => { :argument => true }) do |c|
          inputs(c, "--foo").should == { :foo => "" }
        end
      end
    end

    describe "splats" do
      it "is declared as an input" do
        command(:foo => { :argument => :splat }) do |c|
          inputs(c, "bar").should == { :foo => ["bar"] }
        end
      end

      it "assigns as an empty array if no arguments given" do
        command(:foo => { :argument => :splat }) do |c|
          inputs(c).should == { :foo => [] }
        end
      end

      it "assigns as an array if one argument given" do
        command(:foo => { :argument => :splat }) do |c|
          inputs(c, "foo").should == { :foo => ["foo"] }
        end
      end

      it "assigns as an array if two or more arguments given" do
        command(:foo => { :argument => :splat }) do |c|
          inputs(c, "foo", "bar").should == { :foo => ["foo", "bar"] }
          inputs(c, "foo", "bar", "baz").should ==
            { :foo => ["foo", "bar", "baz"] }
        end
      end

      describe "as flags" do
        it "assigns as an empty array if just name is given" do
          command(:foo => { :argument => :splat }) do |c|
            inputs(c, "--foo").should == { :foo => [] }
          end
        end

        it "assigns as an array if one value given" do
          command(:foo => { :argument => :splat }) do |c|
            inputs(c, "--foo", "bar").should == { :foo => ["bar"] }
          end
        end

        it "accepts comma-separated values" do
          command(:foo => { :argument => :splat }) do |c|
            inputs(c, "--foo", "bar,baz").should == { :foo => ["bar", "baz"] }
          end
        end
      end
    end
  end
end
