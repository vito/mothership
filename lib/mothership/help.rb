require "mothership/base"
require "mothership/help/commands"

module Mothership::Help
  @@groups = []
  @@tree = {}

  class << self
    def has_groups?
      !@@groups.empty?
    end

    # define help groups
    def groups(*tree)
      tree.each do |*args|
        add_group(@@groups, @@tree, *args.first)
      end
    end

    def group(*names)
      if where = find_group(names, @@tree)
        where[:members].collect(&:first)
      else
        []
      end
    end

    def add_to_group(command, names, options)
      where = find_group(names, @@tree)
      raise "unknown help group: #{names.join("/")}" unless where
      
      where[:members] << [command, options]
    end

    private

    def find_group(names, where)
      names.each_with_index do |n, index|
        where = where[:children] unless index == 0
        break unless where

        where = where[n]
        break unless where
      end

      where
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
