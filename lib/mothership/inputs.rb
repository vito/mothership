class Mothership
  class Inputs
    attr_reader :inputs, :given, :global

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
      else
        @given[name]
      end
    end

    def merge(inputs)
      self.class.new(@command, @context, @inputs.merge(inputs), @given)
    end

    def merge_given(inputs)
      self.class.new(@command, @context, @inputs, @given.merge(inputs))
    end

    def without(*names)
      given = @given.dup
      inputs = @inputs.dup
      names.each do |n|
        given.delete(n)
        inputs.delete(n)
      end

      self.class.new(@command, @context, given, inputs)
    end

    def [](name, *args)
      get(name, @context, *args)
    end

    # search:
    # 1. cache
    # 2. cache, singular
    # 3. given
    # 4. given, singular
    # 5. global
    # 6. global, singular
    def get(name, context, *args)
      return @inputs[name] if @inputs.key?(name)

      if meta = @command.inputs[name]
        # special case so #invoke can be called with singular-named inputs
        singular = meta[:singular]
        return @inputs[name] = [@inputs[singular]] if @inputs.key?(singular)

        found, val = find_in(@given, name, meta, context, *args)
      end

      # if not found locally and the default is nil, search globally
      if !found && val.nil? && meta = Mothership.global_option(name)
        found, val = find_in(@global, name, meta, context, *args)
      end

      return val if not found

      @inputs[name] = convert_given(meta, context, val, *args)
    end

    def forget(name)
      @given.delete(name)
      @inputs.delete(name)
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
        val = default_for(meta, context, *args)

        # cache default value
        @inputs[name] = val unless meta[:forget]

        [false, val]
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
        given
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
      elsif meta[:type] == :boolean
        false
      elsif meta[:argument] == :splat
        []
      end
    end
  end
end
