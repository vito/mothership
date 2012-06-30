require "mothership/command"
require "mothership/inputs"

class Mothership
  # all commands
  @@commands = {}

  # parsed global input set
  @@inputs = nil

  # Initialize with the command being executed.
  def initialize(command = nil)
    @command = command
  end

  class << self
    # start defining a new command with the given description
    def desc(description)
      @command = Command.new(self, description)
    end

    # define an input for the current command or the global command
    def input(name, options = {}, &default)
      raise "no current command" unless @command

      @command.add_input(name, options, &default)
    end

    # register a command
    def method_added(name)
      return unless @command

      @command.name = name
      @@commands[name] = @command

      @command = nil
    end

    def alias_command(orig, new)
      @@commands[new] = @@commands[orig]
    end
  end

  def execute(cmd, argv)
    cmd.invoke(Parser.new(cmd).inputs(argv))
  rescue Mothership::Error => e
    puts e
    puts ""
    Mothership::Help.command_usage(cmd)

    @@exit_status = 1
  end

  # invoke a command with the given inputs
  def invoke(name, inputs = {})
    @@commands[name].invoke(inputs)
  end

  def run(inputs = {})
    send(@command.name, Inputs.new(@command, self, inputs))
  end
end
