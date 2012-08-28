require "mothership/base"
require "mothership/callbacks"
require "mothership/command"
require "mothership/parser"
require "mothership/help"
require "mothership/errors"

class Mothership
  # [Mothership::Command] global options
  @@global = Command.new(self, "(global options)")

  # [Fixnum] exit status; reassign as appropriate error code (e.g. 1)
  @@exit_status = 0

  class << self
    # define a global option
    def option(name, options = {}, &default)
      @@global.add_input(name, options, &default)
    end

    # parse argv, by taking the first arg as the command, and the rest as
    # arguments and flags
    #
    # arguments and flags can be in any order; all flags will be parsed out
    # first, and the bits left over will be treated as arguments
    def start(argv)
      global_parser = Parser.new(@@global)
      name, *argv = global_parser.parse_flags(argv, @@commands)

      app = new

      unless name
        app.input = Inputs.new(nil, @@global, {}, {}, global_parser.given)
        return app.default_action
      end

      cmdname = name.gsub("-", "_").to_sym

      cmd = @@commands[cmdname]
      return app.unknown_command(cmdname) unless cmd

      app.execute(cmd, argv, global_parser.given)

      code = @@exit_status

      # reset exit status
      @@exit_status = 0

      exit code
    end

    def global_option(name)
      @@global.inputs[name]
    end
  end

  # set the exit status
  def exit_status(num)
    @@exit_status = num
  end
end
