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
      @@inputs = Inputs.new(@@global, self, {})

      name, *argv =
        Parser.new(@@global).parse_flags(
          @@inputs.inputs,
          argv)

      return new.default_action unless name

      cname = name.gsub("-", "_").to_sym

      cmd = @@commands[cname]

      return new.unknown_command(name) unless cmd

      begin
        cmd.invoke(Parser.new(cmd).inputs(argv))
      rescue Mothership::Error => e
        puts e
        puts ""
        Mothership::Help.command_usage(cmd)

        @@exit_status = 1
      end

      exit @@exit_status
    end
  end

  def exit_status(num)
    @@exit_status = num
  end

  # get value of global option
  def option(name, *args)
    @@inputs[name, *args]
  end

  # test if an option was explicitly provided
  def option_given?(name)
    @@inputs.given? name
  end
end
