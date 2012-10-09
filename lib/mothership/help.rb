require "mothership/base"

module Mothership::Help
  @@groups = []
  @@tree = {}

  class << self
    def has_groups?
      !@@groups.empty?
    end

    def print_help_groups(global = nil, all = false)
      @@groups.each do |commands|
        print_help_group(commands, all)
      end

      command_options(global)
    end

    def unique_commands(commands)
      uniq_commands = []
      cmd_index = {}

      commands.each do |cmd|
        if idx = cmd_index[cmd.name]
          uniq_commands[idx] = cmd
        else
          cmd_index[cmd.name] = uniq_commands.size
          uniq_commands << cmd
        end
      end

      uniq_commands
    end

    def print_help_group(group, all = false, indent = 0)
      return if nothing_printable?(group, all)

      members = group[:members]

      unless all
        members = members.reject do |_, opts|
          opts[:hidden]
        end
      end

      commands = members.collect(&:first)

      i = "  " * indent

      print i
      puts group[:description]

      commands = unique_commands(commands)

      width = 0
      commands.each do |cmd|
        len = cmd.usage.size
        if len > width
          width = len
        end
      end

      commands.each do |cmd|
        puts "#{i}  #{cmd.usage.ljust(width)}\t#{cmd.description}"
      end

      puts "" unless commands.empty?

      group[:children].each do |group|
        print_help_group(group, all, indent + 1)
      end
    end

    # define help groups
    def groups(*tree)
      tree.each do |*args|
        add_group(@@groups, @@tree, *args.first)
      end
    end

    def add_to_group(command, names, options)
      where = @@tree
      top = true
      names.each do |n|
        where = where[:children] unless top
        break unless where

        where = where[n]
        break unless where

        top = false
      end

      unless where
        raise "unknown help group: #{names.join("/")}"
      end

      where[:members] << [command, options]
    end

    def basic_help(commands, global)
      puts "Commands:"

      width = 0
      commands.each do |_, c|
        len = c.usage.size
        width = len if len > width
      end

      commands.each do |_, c|
        puts "  #{c.usage.ljust(width)}\t#{c.description}"
      end

      unless global.flags.empty?
        puts ""
        command_options(global)
      end
    end

    def command_help(cmd)
      puts cmd.description
      puts ""
      command_usage(cmd)
    end

    def command_usage(cmd, io = $stdout)
      io.puts "Usage: #{cmd.usage}"

      unless cmd.flags.empty?
        io.puts ""
        command_options(cmd, io)
      end
    end

    def command_options(cmd, io = $stdout)
      io.puts "Options:"

      rev_flags = Hash.new { |h, k| h[k] = [] }

      cmd.flags.each do |f, n|
        rev_flags[n] << f
      end

      usages = []

      max_width = 0
      rev_flags.collect do |name, fs|
        info = cmd.inputs[name]

        flag = name.to_s.gsub("_", "-")

        full = fs.delete "--#{flag}"

        short = fs.find { |x| x =~ /^-.$/ }
        fs.delete short if short

        if info[:type] == :boolean && info[:default] == true
          full = "--[no-]#{flag}"
        end

        usage = "#{short ? short + "," : "   "} #{([full] + fs).join ", "}"

        unless info[:type] == :boolean
          usage << " #{(info[:value] || name).to_s.upcase}"
        end

        max_width = usage.size if usage.size > max_width

        usages << [usage, info[:description]]
      end

      usages.sort! { |a, b| a.first <=> b.first }

      usages.each do |u, d|
        if d
          io.puts "  #{u.ljust(max_width)}    #{d}"
        else
          io.puts "  #{u}"
        end
      end
    end

    private

    def nothing_printable?(group, all = false)
      group[:members].reject { |_, opts| !all && opts[:hidden] }.empty? &&
        group[:children].all? { |g| nothing_printable?(g) }
    end

    def add_group(groups, tree, name, desc, *subs)
      members = []

      meta = { :members => members, :children => [] }
      groups << meta

      tree[name] = { :members => members, :children => {} }

      meta[:description] = desc

      subs.each do |*args|
        add_group(meta[:children], tree[name][:children], *args.first)
      end
    end
  end
end

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
      Mothership::Help.command_help(@@commands[name.gsub("-", "_").to_sym])
    elsif Help.has_groups?
      unless input[:all]
        puts "Showing basic command set. Pass --all to list all commands."
        puts ""
      end

      Mothership::Help.print_help_groups(@@global, input[:all])
    else
      Mothership::Help.basic_help(@@commands, @@global)
    end
  end
end
