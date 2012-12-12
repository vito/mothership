require "mothership/inputs"

class Mothership
  class Command
    attr_accessor :name, :description, :interactions

    attr_reader :context, :inputs, :arguments, :flags

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

    def display_name
      @name.to_s.gsub("_", "-")
    end

    def usage
      args = [display_name]
      @arguments.each do |a|
        name = (a[:value] || a[:name]).to_s.upcase
        input = @inputs[a[:name]]

        if a[:type] == :splat
          args << "#{name}..."
        elsif a[:type] == :optional || input.key?(:default) || \
                input.key?(:interact)
          args << "[#{name}]"
        else
          args << name
        end
      end

      args.join(" ")
    end

    def invoke(inputs = {}, given = {}, global = {})
      @before.each { |f, c| c.new.instance_exec(&f) }

      name = @name

      ctx = @context.new(self)
      ctx.extend @interactions if @interactions

      ctx.input = Inputs.new(self, ctx, inputs, given, global)


      action = proc do |*given_inputs|
        ctx.input = given_inputs.first || ctx.input
        ctx.run(name)
      end

      cmd = self
      @around.each do |a, c|
        before = action

        sub = c.new(cmd, ctx.input)
        action = proc do |*given_inputs|
          ctx.input = given_inputs.first || ctx.input
          sub.instance_exec(before, ctx.input, &a)
        end
      end

      res = ctx.instance_exec(ctx.input, &action)

      @after.each { |f, c| c.new.instance_exec(&f) }

      res
    end

    def add_input(name, options = {}, &interact)
      options[:interact] = interact if interact
      options[:description] = options.delete(:desc) if options.key?(:desc)

      options[:type] ||=
        case options[:default]
        when true, false
          :boolean
        when Integer
          :integer
        when Float
          :floating
        end

      unless options[:hidden]
        @flags["--#{name.to_s.gsub("_", "-")}"] = name

        if options[:singular]
          @flags["--#{options[:singular]}"] = name
        end

        if aliases = options[:aliases] || options[:alias]
          Array(aliases).each do |a|
            @flags[a] = name
          end
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

        @arguments <<
          { :name => name,
            :type => type,
            :value => options[:value]
          }
      end

      @inputs[name] = options
    end
  end
end
