require "mothership/help/printer"

class Mothership
  class << self
    # add command to help group
    def group(*names)
      options =
        if names.last.is_a? Hash
          names.pop
        else
          {}
        end

      Mothership::Help.add_to_group(@command, names, options)
    end
  end

  def default_action
    invoke :help
  end

  def unknown_command(name)
    $stderr.print "Unknown command '#{name.to_s.gsub("_", "-")}'. "
    $stderr.puts "See 'help' for available commands."
    exit_status 1
  end

  desc "Help!"
  input :command, :argument => :optional
  input :all, :type => :boolean
  def help
    if name = input[:command]
      if cmd = @@commands[name.gsub("-", "_").to_sym]
        Mothership::Help.command_help(cmd)
      else
        unknown_command(name)
      end
    elsif Help.has_groups?
      unless input[:all]
        puts "Showing basic command set. Run with 'help --all' to list all commands."
        puts ""
      end

      Mothership::Help.print_help_groups(@@global, input[:all])
    else
      Mothership::Help.basic_help(@@commands, @@global)
    end
  end
end
