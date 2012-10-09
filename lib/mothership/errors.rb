class Mothership
  class Error < RuntimeError
  end

  class MissingArgument < Error
    def initialize(cmd, arg)
      @command = cmd
      @argument = arg
    end

    def to_s
      "#{@command.display_name}: missing input '#{@argument}'"
    end
  end

  class ExtraArguments < Error
    def initialize(cmd, extra)
      @command = cmd
      @extra = extra
    end

    def to_s
      "#{@command.display_name}: too many arguments; extra: #{@extra.join(" ")}"
    end
  end

  class TypeMismatch < Error
    def initialize(cmd, input, type)
      @command = cmd
      @input = input
      @type = type
    end

    def to_s
      "#{@command.display_name}: expected #{@type} value for #{@input}"
    end
  end
end
