require "spec_helper"

describe Mothership::Parser do
  describe "flags" do
    describe "any" do
      it "accepts --foo=bar and --foo bar" do
        command(:foo => {}) do |c|
          inputs(c, "--foo=bar").should == { :foo => "bar" }
          inputs(c, "--foo", "bar").should == { :foo => "bar" }
        end
      end

      it "accepts --foo-bar bar as :foo_bar => \"bar\"" do
        command(:foo_bar => {}) do |c|
          inputs(c, "--foo-bar", "bar").should == { :foo_bar => "bar" }
        end
      end

      it "accepts --foo as :foo => \"\"" do
        command(:foo => {}) do |c|
          inputs(c, "--foo").should == { :foo => "" }
        end
      end
    end

    describe :integer do
      it "interprets --foo 1 as :foo => 1" do
        command(:foo => { :type => :integer }) do |c|
          inputs(c, "--foo", "1").should == { :foo => 1 }
        end
      end

      it "fails with --foo bar" do
        command(:foo => { :type => :integer }) do |c|
          proc {
            inputs(c, "--foo", "bar")
          }.should raise_error(Mothership::TypeMismatch)
        end
      end

      it "fails with --foo" do
        command(:foo => { :type => :integer }) do |c|
          proc {
            inputs(c, "--foo")
          }.should raise_error(Mothership::TypeMismatch)
        end
      end
    end

    describe :float do
      it "interprets --foo 1 as :foo => 1.0" do
        command(:foo => { :type => :float }) do |c|
          inputs(c, "--foo", "1").should == { :foo => 1.0 }
        end
      end

      it "interprets --foo 1. as :foo => 1.0" do
        command(:foo => { :type => :float }) do |c|
          inputs(c, "--foo", "1.").should == { :foo => 1.0 }
        end
      end

      it "interprets --foo 2.5 as :foo => 2.5" do
        command(:foo => { :type => :float }) do |c|
          inputs(c, "--foo", "2.5").should == { :foo => 2.5 }
        end
      end

      it "fails with --foo bar" do
        command(:foo => { :type => :float }) do |c|
          proc {
            inputs(c, "--foo", "bar")
          }.should raise_error(Mothership::TypeMismatch)
        end
      end

      it "fails with --foo" do
        command(:foo => { :type => :float }) do |c|
          proc {
            inputs(c, "--foo")
          }.should raise_error(Mothership::TypeMismatch)
        end
      end
    end

    describe :boolean do
      it "interprets --foo as :foo => true" do
        command(:foo => { :type => :boolean }) do |c|
          inputs(c, "--foo").should == { :foo => true }
        end
      end

      it "interprets --no-foo as :foo => false" do
        command(:foo => { :type => :boolean }) do |c|
          inputs(c, "--no-foo").should == { :foo => false }
        end
      end
      it "interprets --foo true as :foo => true" do
        command(:foo => { :type => :boolean }) do |c|
          inputs(c, "--foo", "true").should == { :foo => true }
        end
      end

      it "interprets --no-foo true as :foo => false" do
        command(:foo => { :type => :boolean }) do |c|
          inputs(c, "--no-foo", "true").should == { :foo => false }
        end
      end
      it "interprets --foo false as :foo => false" do
        command(:foo => { :type => :boolean }) do |c|
          inputs(c, "--foo", "false").should == { :foo => false }
        end
      end

      it "interprets --no-foo false as :foo => true" do
        command(:foo => { :type => :boolean }) do |c|
          inputs(c, "--no-foo", "false").should == { :foo => true }
        end
      end
    end
  end
end
