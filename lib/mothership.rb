require "mothership/base"
require "mothership/callbacks"
require "mothership/command"
require "mothership/parser"
require "mothership/help"
require "mothership/errors"

class Mothership
  # [Mothership::Command] global options
  @@global = Command.new(self, "(global options)")

  # [Mothershp::Inputs] inputs from global options
  @@inputs = nil

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
      @@inputs = Inputs.new(@@global)

      name, *argv =
        Parser.new(@@global).parse_flags(
          @@inputs.inputs,
          argv,
          @@commands)

      app = new

      return app.default_action unless name

      cmdname = name.gsub("-", "_").to_sym

      cmd = @@commands[cmdname]
      return app.unknown_command(cmdname) unless cmd

      app.execute(cmd, argv)

      exit @@exit_status
    end
  end

  # set the exit status
  def exit_status(num)
    @@exit_status = num
  end

  # get value of global option
  def option(name, *args)
    @@inputs.get(name, self, *args)
  end

  # test if an option was explicitly provided
  def option_given?(name)
    @@inputs.given? name
  end
end
