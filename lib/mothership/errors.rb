class Mothership
  class Error < RuntimeError
  end

  class MissingArgument < Error
    def initialize(cmd, arg)
      @command = cmd
      @argument = arg
    end

    def to_s
      "#{@command}: missing input '#{@argument}'"
    end
  end

  class ExtraArguments < Error
    def initialize(cmd)
      @command = cmd
    end

    def to_s
      "#{@command}: too many arguments"
    end
  end

  class TypeMismatch < Error
    def initialize(cmd, input, type)
      @command = cmd
      @input = input
      @type = type
    end

    def to_s
      "#{@command}: expected #{@type} value for #{@input}"
    end
  end
end
