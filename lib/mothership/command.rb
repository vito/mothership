require "mothership/inputs"

class Mothership::Command
  attr_accessor :name, :description, :inputs, :arguments, :flags

  def initialize(context, description = nil, inputs = {})
    @context = context
    @description = description
    @inputs = inputs

    # inputs that act as arguments
    @arguments = []

    # flag -> input (e.g. --name -> :name)
    @flags = {}
  end

  def usage
    str = @name.to_s

    @arguments.each do |a|
      name = a[:name].to_s.upcase

      if a[:splat]
        str << " #{name}..."
      else
        str << " #{name}"
      end
    end

    str
  end

  def invoke(inputs)
    ctx = @context.new

    ctx.send(
      @name,
      Mothership::Inputs.new(self, ctx, inputs))
  end

  def add_input(name, options = {}, &default)
    options[:default] = default if default
    options[:description] = options.delete(:desc) if options.key?(:desc)

    @flags["--#{name.to_s.gsub("_", "-")}"] = name
    if aliases = options[:aliases] || options[:alias]
      Array(aliases).each do |a|
        @flags[a] = name
      end
    end

    # :argument => true means accept as single argument
    # :argument => :foo is shorthand for :argument => {:foo => true}
    if opts = options[:argument]
      arg =
        case opts
        when true
          {}
        when Symbol
          {opts => true}
        when Hash
          opts
        end

      arg[:name] = name

      options[:argument] = arg

      @arguments << arg
    end

    @inputs[name] = options
  end
end
