require "mothership"

module MothershipHelpers
  def command(inputs = {})
    cmd = Mothership::Command.new(Mothership)

    inputs.each do |name, opts|
      cmd.add_input(name, opts)
    end

    if block_given?
      yield cmd
    else
      cmd
    end
  end

  def inputs(cmd, *argv)
    input_hash = {}
    given = Mothership::Parser.new(cmd).parse_argv(argv)
    inputs = Mothership::Inputs.new(cmd, nil, {}, given)
    given.each_key do |k|
      input_hash[k] = inputs[k]
    end
    input_hash
  end
end

RSpec.configure do |c|
  c.include MothershipHelpers
end
