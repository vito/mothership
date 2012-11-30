require "spec_helper"

describe Mothership::Parser do
  describe "combinations" do
    describe "arguments & flags" do
      it "parses flags placed after arguments" do
        command(:flag => {}, :arg => { :argument => true }) do |c|
          inputs(c, "foo", "--flag", "bar").should ==
            { :arg => "foo", :flag => "bar" }
        end
      end

      it "parses flags placed before arguments" do
        command(:flag => {}, :arg => { :argument => true }) do |c|
          inputs(c, "--flag", "bar", "foo").should ==
            { :arg => "foo", :flag => "bar" }
        end
      end

      it "parses flags placed between arguments" do
        command([
            [:flag, {}],
            [:arg1, { :argument => true }],
            [:arg2, { :argument => true }]]) do |c|
          inputs(c, "foo", "--flag", "bar", "baz").should ==
            { :arg1 => "foo", :flag => "bar", :arg2 => "baz" }
        end
      end

      it "skips parsing arguments that were passed as flags" do
        command([
            [:arg1, { :argument => true }],
            [:arg2, { :argument => true }]]) do |c|
          inputs(c, "baz", "--arg1", "foo").should ==
            { :arg1 => "foo", :arg2 => "baz" }
        end
      end
    end

    describe "arguments & splats" do
      it "consumes the rest of the arguments" do
        command([
            [:foo, { :argument => :splat }],
            [:bar, { :argument => true }]]) do |c|
          proc {
            inputs(c, "fizz", "buzz")
          }.should raise_error(Mothership::MissingArgument)
        end
      end

      it "consumes arguments after normal arguments" do
        command([
            [:foo, { :argument => true }],
            [:bar, { :argument => :splat }]]) do |c|
          inputs(c, "fizz", "buzz").should ==
            { :foo => "fizz", :bar => ["buzz"] }
        end
      end

      it "appears empty when there are no arguments left after normal" do
        command([
            [:foo, { :argument => true }],
            [:bar, { :argument => :splat }]]) do |c|
          inputs(c, "fizz").should ==
            { :foo => "fizz", :bar => [] }
        end
      end
    end

    describe "splats & flags" do
      it "parses flags placed after splats" do
        command(:flag => {}, :arg => { :argument => :splat }) do |c|
          inputs(c, "foo", "--flag", "bar").should ==
            { :arg => ["foo"], :flag => "bar" }
        end
      end

      it "parses flags placed before splats" do
        command(:flag => {}, :arg => { :argument => :splat }) do |c|
          inputs(c, "--flag", "bar", "foo").should ==
            { :arg => ["foo"], :flag => "bar" }
        end
      end

      it "parses flags placed between splat arguments" do
        command([
            [:flag, {}],
            [:arg, { :argument => :splat }]]) do |c|
          inputs(c, "foo", "--flag", "bar", "baz").should ==
            { :arg => ["foo", "baz"], :flag => "bar" }
        end
      end

      it "skips parsing splats that were passed as flags" do
        command([
            [:arg1, { :argument => :splat }],
            [:arg2, { :argument => true }]]) do |c|
          inputs(c, "baz", "--arg1", "foo").should ==
            { :arg1 => ["foo"], :arg2 => "baz" }
        end
      end
    end
  end
end
