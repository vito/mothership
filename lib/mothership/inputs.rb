class Mothership
  class Inputs
    attr_reader :inputs

    def initialize(command, context = nil, inputs = {})
      @command = command
      @context = context
      @inputs = inputs
      @cache = {}
    end

    def given?(name)
      @inputs.key?(name)
    end

    def given(name)
      @inputs[name]
    end

    def merge(inputs)
      self.class.new(@command, @context, @inputs.merge(inputs))
    end

    def without(*names)
      inputs = @inputs.dup
      names.each do |n|
        inputs.delete(n)
      end

      self.class.new(@command, @context, inputs)
    end

    def [](name, *args)
      get(name, @context, *args)
    end

    def get(name, context, *args)
      return @cache[name] if @cache.key? name

      meta = @command.inputs[name]
      return unless meta

      if @inputs.key?(name) && @inputs[name] != []
        val =
          if convert = meta[:from_given]
            if @inputs[name].is_a?(Array)
              @inputs[name].collect do |i|
                @context.instance_exec(i, *args, &convert)
              end
            else
              @context.instance_exec(@inputs[name], *args, &convert)
            end
          else
            @inputs[name]
          end

        return @cache[name] = val
      end

      val =
        if meta[:default].respond_to? :to_proc
          unless context
            raise "no context for input request"
          end

          context.instance_exec(*args, &meta[:default])
        elsif meta[:default]
          meta[:default]
        elsif meta[:type] == :boolean
          false
        elsif meta[:argument] == :splat
          if meta[:singular] && single = @inputs[meta[:singular]]
            [single]
          else
            []
          end
        end

      unless meta[:forget]
        @cache[name] = val
      end

      val
    end

    def forget(name)
      @cache.delete(name)
      @inputs.delete(name)
    end
  end
end
