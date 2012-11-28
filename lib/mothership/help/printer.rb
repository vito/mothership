module Mothership::Help
  class << self
    def print_help_groups(global = nil, all = false)
      @@groups.each do |commands|
        print_help_group(commands, all)
      end

      command_options(global)
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
        next if info[:hidden]

        flag = name.to_s.gsub("_", "-")

        # move full form to the front
        fs.unshift fs.delete("--#{flag}")

        if short = fs.find { |x| x =~ /^-.$/ }
          fs.delete short
        end

        if info[:type] == :boolean && info[:default]
          fs[0] = "--[no-]#{flag}"
        end

        if info.key?(:default) && info.key?(:interact)
          fs.unshift "--ask-#{flag}"
        end

        usage = "#{short ? short + "," : "   "} #{fs.join ", "}"

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
  end
end
