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
    Mothership::Parser.new(cmd).inputs(argv)
  end
end

RSpec.configure do |c|
  c.include MothershipHelpers
end
