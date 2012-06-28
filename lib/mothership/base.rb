class Mothership
  # all commands
  @@commands = {}

  # parsed global input set
  @@inputs = nil

  class << self
    # start defining a new command with the given description
    def desc(description)
      @command = Command.new(self, description)
    end

    # define an input for the current command or the global command
    def input(name, options = {}, &default)
      raise "no current command!" unless @command

      @command.add_input(name, options, &default)
    end

    # register a command
    def method_added(name)
      return unless @command

      @command.name = name
      @@commands[name] = @command

      @command = nil
    end
  end

  # invoke a command with the given inputs
  def invoke(name, inputs = {})
    @@commands[name].invoke(inputs)
  end
end
