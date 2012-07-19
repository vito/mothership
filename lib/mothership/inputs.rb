class Mothership
  class Inputs
    attr_reader :inputs

    def initialize(command, context = nil, given = {}, inputs = {})
      @command = command
      @context = context
      @given = given
      @inputs = inputs
    end

    def given?(name)
      @given.key?(name)
    end

    def given(name)
      @given[name]
    end

    def merge(inputs)
      self.class.new(@command, @context, @given, @inputs.merge(inputs))
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

    def get(name, context, *args)
      return @inputs[name] if @inputs.key?(name)

      meta = @command.inputs[name]
      return unless meta

      singular = meta[:singular]
      return @inputs[name] = [@inputs[singular]] if @inputs.key?(singular)

      given = @given[name] if @given.key?(name)

      # value given; convert if needed
      if given && given != []
        return @inputs[name] = convert_given(meta, context, given, *args)
      end

      # no value given; set as default
      val = default_for(meta, context, *args)

      unless meta[:forget]
        @inputs[name] = val
      end

      val
    end

    def forget(name)
      @given.delete(name)
      @inputs.delete(name)
    end

    private

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
