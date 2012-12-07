class Mothership
  class Inputs
    attr_reader :inputs, :given, :global

    # the input being processed; set during #get
    attr_reader :current_input

    def initialize(
        command, context = nil,
        inputs = {}, given = {}, global = {})
      @command = command
      @context = context
      @inputs = inputs
      @given = given
      @global = global
    end

    def given?(name)
      @inputs.key?(name) || @given.key?(name)
    end

    def given(name)
      if @inputs.key?(name)
        @inputs[name]
      elsif (given = @given[name]) != :interact
        given
      end
    end

    def merge(inputs)
      self.class.new(@command, @context, @inputs.merge(inputs), @given, @global)
    end

    def merge_given(given)
      self.class.new(@command, @context, @inputs, @given.merge(given), @global)
    end

    def rebase(inputs)
      self.class.new(@command, @context, inputs.merge(@inputs), @given, @global)
    end

    def rebase_given(given)
      self.class.new(@command, @context, @inputs, given.merge(@given), @global)
    end

    def without(*names)
      given = @given.dup
      inputs = @inputs.dup
      names.each do |n|
        given.delete(n)
        inputs.delete(n)
      end

      self.class.new(@command, @context, inputs, given, @global)
    end

    def [](name, *args)
      return @inputs[name] if @inputs.key?(name)

      if @command && meta = @command.inputs[name]
        # special case so #invoke can be called with singular-named inputs
        singular = meta[:singular]

        if @inputs.key?(singular)
          return @inputs[name] = [@inputs[singular]]
        end
      end

      found, val = get(name, @context, *args)

      @inputs[name] = val unless meta && meta[:forget]

      val
    end

    def interact(name, *args)
      meta =
        if @command
          @command.inputs[name]
        else
          Mothership.global_option(name)
        end

      if interact = meta[:interact]
        @context.instance_exec(*args, &interact)
      end
    end

    # search:
    # 1. cache
    # 2. cache, singular
    # 3. given
    # 4. given, singular
    # 5. global
    # 6. global, singular
    def get(name, context, *args)
      before_input = @current_input
      @current_input = [name, args]

      if @command && meta = @command.inputs[name]
        found, val = find_in(@given, name, meta, context, *args)
      elsif @global.is_a?(self.class)
        return @global.get(name, context, *args)
      elsif @global.key?(name)
        return [true, @global[name]]
      end

      return [false, val] if not found

      if val == :interact && interact = meta[:interact]
        [true, context.instance_exec(*args, &interact)]
      else
        [true, convert_given(meta, context, val, *args)]
      end
    ensure
      @current_input = before_input
    end

    def forget(name)
      @inputs.delete(name)
      @given.delete(name)
    end

    def interactive?(name)
      @given[name] == :interact
    end

    private

    def find_in(where, name, meta, context, *args)
      singular = meta[:singular]

      if where.key?(name)
        [true, where[name]]
      elsif where.key?(singular)
        [true, [where[singular]]]
      else
        # no value given; set as default
        [false, default_for(meta, context, *args)]
      end
    end

    def convert_given(meta, context, given, *args)
      if convert = meta[:from_given]
        if given.is_a?(Array)
          given.collect do |i|
            context.instance_exec(i, *args, &convert)
          end
        else
          context.instance_exec(given, *args, &convert)
        end
      else
        case meta[:type]
        when :integer, :number, :numeric
          given.to_i
        when :float
          given.to_f
        when :boolean
          given == "true"
        else
          given
        end
      end
    end

    def default_for(meta, context, *args)
      if meta.key?(:default)
        default = meta[:default]

        if default.respond_to? :to_proc
          context.instance_exec(*args, &default)
        else
          default
        end
      elsif interact = meta[:interact]
        context.instance_exec(*args, &interact)
      elsif meta[:type] == :boolean
        false
      elsif meta[:argument] == :splat
        []
      end
    end
  end
end
