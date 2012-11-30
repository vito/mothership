require "spec_helper"

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

    describe "optional & required ordering" do
      it "parses required arguments positioned before optionals first" do
        command([
            [:foo, { :argument => true }],
            [:foo2, { :argument => true }],
            [:bar, { :argument => :optional }],
            [:bar2, { :argument => :optional }]]) do |c|
          inputs(c, "a", "b").should == { :foo => "a", :foo2 => "b" }

          inputs(c, "a", "b", "c").should ==
            { :foo => "a", :foo2 => "b", :bar => "c" }

          inputs(c, "a", "b", "c", "d").should ==
            { :foo => "a", :foo2 => "b", :bar => "c", :bar2 => "d" }
        end
      end

      it "parses required arguments positioned after optionals first " do
        command([
            [:foo, { :argument => :optional }],
            [:foo2, { :argument => :optional }],
            [:bar, { :argument => true }],
            [:bar2, { :argument => true }]]) do |c|
          inputs(c, "a", "b").should == { :bar => "a", :bar2 => "b" }

          inputs(c, "a", "b", "c").should ==
            { :bar => "b", :bar2 => "c", :foo => "a" }

          inputs(c, "a", "b", "c", "d").should ==
            { :bar => "c", :bar2 => "d", :foo => "a", :foo2 => "b" }
        end
      end

      it "parses required arguments positioned around optionals first " do
        command([
            [:foo, { :argument => true }],
            [:foo2, { :argument => :optional }],
            [:bar, { :argument => :optional }],
            [:bar2, { :argument => true }]]) do |c|
          inputs(c, "a", "b").should == { :foo => "a", :bar2 => "b" }

          inputs(c, "a", "b", "c").should ==
            { :foo => "a", :foo2 => "b", :bar2 => "c" }

          inputs(c, "a", "b", "c", "d").should ==
            { :foo => "a", :foo2 => "b", :bar => "c", :bar2 => "d" }
        end
      end

      it "parses required arguments positioned between optionals first " do
        command([
            [:foo, { :argument => :optional }],
            [:foo2, { :argument => true }],
            [:bar, { :argument => true }],
            [:bar2, { :argument => :optional }]]) do |c|
          inputs(c, "a", "b").should == { :foo2 => "a", :bar => "b" }

          inputs(c, "a", "b", "c").should ==
            { :foo => "a", :foo2 => "b", :bar => "c" }

          inputs(c, "a", "b", "c", "d").should ==
            { :foo => "a", :foo2 => "b", :bar => "c", :bar2 => "d" }
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
