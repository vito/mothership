require "mothership/inputs"

class Mothership
  class Command
    attr_accessor :name, :description

    attr_reader :inputs, :arguments, :flags

    attr_reader :before, :after, :around, :filters

    def initialize(context, description = nil)
      @context = context
      @description = description
      @aliases = []

      # inputs accepted by command
      @inputs = {}

      # inputs that act as arguments
      @arguments = []

      # flag -> input (e.g. --name -> :name)
      @flags = {}

      # various callbacks
      @before = []
      @after = []
      @around = []
      @filters = Hash.new { |h, k| h[k] = [] }
    end

    def usage
      str = @name.to_s.gsub("_", "-")

      @arguments.each do |a|
        name = a[:name].to_s.upcase

        if a[:splat]
          str << " #{name}..."
        elsif a[:optional]
          str << " [#{name}]"
        else
          str << " #{name}"
        end
      end

      str
    end

    def invoke(inputs)
      @before.each(&:call)

      ctx = @context.new(self)
      action = proc do |*given_inputs|
        ctx.run_command(given_inputs.first || inputs)
      end

      @around.each do |a|
        before = action
        action = proc do |*given_inputs|
          ctx.instance_exec(before, given_inputs.first || inputs, &a)
        end
      end

      res = ctx.instance_exec(inputs, &action)

      @after.each(&:call)

      res
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
end
