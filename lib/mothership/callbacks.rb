class Mothership
  # temporary filters via #with_filters
  #
  # command => { tag => [callbacks] }
  @@filters = Hash.new { |h, k| h[k] = Hash.new { |h, k| h[k] = [] } }

  class << self
    # register a callback that's evaluated before a command is run
    def before(name, &callback)
      @@commands[name].before << [callback, self]
    end

    # register a callback that's evaluated after a command is run
    def after(name, &callback)
      @@commands[name].after << [callback, self]
    end

    # register a callback that's evaluated around a command, controlling its
    # evaluation (i.e. inputs)
    def around(name, &callback)
      @@commands[name].around << [callback, self]
    end

    # register a callback that's evaluated when a command uses the given
    # filter
    def filter(name, tag, &callback)
      @@commands[name].filters[tag] << [callback, self]
    end

    # change an argument's status, i.e. optional, splat, or required
    def change_argument(name, arg, to)
      changed = false

      @@commands[name].arguments.each do |a|
        if a[:name] == arg
          a[:type] = to
          changed = true
        end
      end

      changed
    end

    # add an input/flag to a command
    def add_input(cmd, name, options = {}, &interact)
      @@commands[cmd].add_input(name, options, &interact)
    end
  end

  # filter a value through any plugins
  def filter(tag, val)
    if @@filters.key?(@command.name) &&
         @@filters[@command.name].key?(tag)
      @@filters[@command.name][tag].each do |f, ctx|
        val = ctx.instance_exec(val, &f)
      end
    end

    @command.filters[tag].each do |f, c|
      val = c.new.instance_exec(val, &f)
    end

    val
  end

  # temporary dynamically-scoped filters
  def with_filters(filters)
    filters.each do |cmd, callbacks|
      callbacks.each do |tag, callback|
        @@filters[cmd][tag] << [callback, self]
      end
    end

    yield
  ensure
    filters.each do |cmd, callbacks|
      callbacks.each do |tag, callback|
        @@filters[cmd][tag].pop
        @@filters[cmd].delete(tag) if @@filters[cmd][tag].empty?
      end

      @@filters.delete(cmd) if @@filters[cmd].empty?
    end
  end
end
