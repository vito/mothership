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

    def inspect
      "\#<Command '#{@name}'>"
    end

    def usage
      str = @name.to_s.gsub("_", "-")

      @arguments.each do |a|
        name = a[:name].to_s.upcase

        case a[:type]
        when :splat
          str << " #{name}..."
        when :optional
          str << " [#{name}]"
        else
          str << " #{name}"
        end
      end

      str
    end

    def invoke(inputs)
      input = Inputs.new(self, @context, inputs)

      @before.each { |f, c| c.new.instance_exec(&f) }

      name = @name
      ctx = @context.new(self)
      action = proc do |*given_inputs|
        ctx.send(name, given_inputs.first || input)
      end

      cmd = self
      @around.each do |a, c|
        before = action

        sub = c.new(cmd)
        action = proc do |*given_inputs|
          sub.instance_exec(before, given_inputs.first || input, &a)
        end
      end

      res = ctx.instance_exec(input, &action)

      @after.each { |f, c| c.new.instance_exec(&f) }

      res
    end

    def add_input(name, options = {}, &default)
      options[:default] = default if default
      options[:description] = options.delete(:desc) if options.key?(:desc)

      @flags["--#{name.to_s.gsub("_", "-")}"] = name

      if options[:singular]
        @flags["--#{options[:singular]}"] = name
      end

      if aliases = options[:aliases] || options[:alias]
        Array(aliases).each do |a|
          @flags[a] = name
        end
      end

      # :argument => true means accept as single argument
      # :argument => :foo is shorthand for :argument => {:type => :foo}
      if opts = options[:argument]
        type =
          case opts
          when true
            :normal
          when Symbol
            opts
          when Hash
            opts[:type]
          end

        options[:argument] = type

        @arguments << { :name => name, :type => type }
      end

      @inputs[name] = options
    end
  end
end
