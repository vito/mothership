require "mothership/base"
require "mothership/command"
require "mothership/parser"
require "mothership/help"

class Mothership
  # global options
  @@global = Command.new(self, "(global options)")

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
      return new.invoke(:help) if argv.empty?

      @@inputs = Inputs.new(@@global, self, {})

      name, *argv =
        Parser.new(@@global).parse_flags(
          @@inputs.inputs,
          argv)

      cname = name.gsub("-", "_").to_sym

      cmd = @@commands[cname]

      raise "unknown command '#{name}'" unless cmd

      cmd.invoke(Parser.new(cmd).inputs(argv))
    end
  end

  # get value of global option
  def option(name, *args)
    @@inputs[name, *args]
  end

  desc "Help!"
  input :command, :argument => :optional
  input :all, :type => :boolean
  def help(input)
    if name = input[:command]
      Mothership::Help.command_help(@@commands[name.to_sym])
    elsif Help.has_groups?
      Mothership::Help.print_help_groups(input[:all])
    else
      Mothership::Help.basic_help(@@commands, @@global)
    end
  end
end
