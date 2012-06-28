module Mothership::Help
  @@groups = []
  @@tree = {}

  class << self
    def groups
      @@groups
    end

    def tree
      @@tree
    end

    def has_groups?
      !@@groups.empty?
    end

    def nothing_printable?(group, all = false)
      group[:members].reject { |_, opts| !all && opts[:hidden] }.empty? &&
        group[:children].all? { |g| nothing_printable?(g) }
    end

    def print_help_groups(all = false)
      @@groups.each do |commands|
        print_help_group(commands, all)
      end
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
        raise "Unknown help group: #{names.join("/")}"
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
      puts "Usage: #{cmd.usage}"

      unless cmd.flags.empty?
        puts ""
        command_options(cmd)
      end
    end

    def command_options(cmd)
      puts "Options:"

      rev_flags = Hash.new { |h, k| h[k] = [] }

      cmd.flags.each do |f, n|
        rev_flags[n] << f
      end

      max_width = 0
      usages = []

      rev_flags.collect do |i, fs|
        info = cmd.inputs[i]

        usage =
          case info[:type]
          when :boolean
            (fs + ["--no-#{i}"]).join(", ")
          when :integer
            fs.join(", ") + " integer"
          else
            fs.join(", ") + " #{i.to_s.upcase}"
          end

        max_width = usage.size if usage.size > max_width

        usages << [usage, info[:description]]
      end

      usages.each do |u, d|
        if d
          puts "  #{u.ljust(max_width)}   #{d}"
        else
          puts "  #{u}"
        end
      end
    end

    private

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

class << Mothership
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
