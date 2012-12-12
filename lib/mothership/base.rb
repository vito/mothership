require "mothership/command"
require "mothership/inputs"

class Mothership
  # all commands
  @@commands = {}

  attr_accessor :input

  # Initialize with the command being executed.
  def initialize(command = nil, input = nil)
    @command = command
    @input = input
  end

  class << self
    # all of the defined commands
    def commands
      @@commands
    end

    # start defining a new command with the given description
    def desc(description)
      @command = Command.new(self, description)
    end

    # define an input for the current command or the global command
    def input(name, options = {}, &interact)
      raise "no current command" unless @command

      @command.add_input(name, options, &interact)
    end

    # specify a module that defines interactions for each input
    def interactions(mod)
      @command.interactions = mod
    end

    # register a command
    def method_added(name)
      return unless @command

      @command.name = name
      @@commands[name] = @command

      @command = nil
    end

    def alias_command(new, orig = nil)
      @@commands[new] = orig ? @@commands[orig] : @command
    end
  end

  def execute(cmd, argv, global = {})
    cmd.invoke({}, Parser.new(cmd).parse_argv(argv), global)
  rescue Mothership::Error => e
    $stderr.puts e
    $stderr.puts ""
    Mothership::Help.command_usage(cmd, $stderr)

    exit_status 1
  end

  # wrap this with your error handling/etc.
  def run(name)
    send(name)
  end

  # invoke a command with inputs
  def invoke(
      name, inputs = {}, given = {}, global = @input ? @input.global : {})
    if cmd = @@commands[name]
      cmd.invoke(inputs, given, global)
    else
      unknown_command(name)
    end
  end

  # explicitly perform the interaction of an input
  #
  # if no input specified, assume current input and reuse the arguments
  #
  # example:
  #   input(:foo, :default => proc { |foos|
  #           foos.find { |f| f.name == "XYZ" } ||
  #             interact
  #         }) { |foos|
  #     ask("Foo?", :choices => foos, :display => proc(&:name))
  #   }
  def interact(input = nil, *args)
    unless input
      input, args = @input.current_input
    end

    raise "no active input" unless input

    @input.interact(input, self, *args)
  end
end
