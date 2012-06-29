class Mothership
  # temporary filters via #with_filters
  #
  # command => { tag => [callbacks] }
  @@filters = Hash.new { |h, k| h[k] = Hash.new { |h, k| h[k] = [] } }

  class << self
    # register a callback that's evaluated before a command is run
    def before(name, &callback)
      @@commands[name].before << callback
    end

    # register a callback that's evaluated after a command is run
    def after(name, &callback)
      @@commands[name].after << callback
    end

    # register a callback that's evaluated around a command, controlling its
    # evaluation (i.e. inputs)
    def around(name, &callback)
      @@commands[name].around << callback
    end

    # register a callback that's evaluated when a command uses the given
    # filter
    def filter(name, tag, &callback)
      @@commands[name].filters[tag] << callback
    end
  end

  # filter a value through any plugins
  def filter(tag, val)
    if @@filters.key?(@command.name) &&
         @@filters[@command.name].key?(tag)
      @@filters[@command.name][tag].each do |f|
        val = f.call val
      end
    end

    @command.filters[tag].each do |f|
      val = f.call val
    end

    val
  end

  # temporary dynamically-scoped filters
  def with_filters(filters)
    filters.each do |cmd, callbacks|
      callbacks.each do |tag, callback|
        @@filters[cmd][tag] << callback
      end
    end

    yield
  ensure
    filters.each do |cmd, callbacks|
      callbacks.each do |tag, callback|
        @@filters[cmd][tag].delete callback
      end

      @@filters[cmd].delete(tag) if @@filters[cmd][tag].empty?
      @@filters.delete(cmd) if @@filters[cmd].empty?
    end
  end
end
