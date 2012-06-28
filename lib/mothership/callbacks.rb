class Mothership
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
    @command.filters[tag].each do |f|
      val = f.call val
    end

    val
  end
end
