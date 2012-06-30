class Mothership
  class Inputs
    attr_reader :inputs

    def initialize(command, context, inputs = {})
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

    def [](name, *args)
      return @inputs[name] if @inputs.key?(name) && @inputs[name] != []
      return @cache[name] if @cache.key? name

      meta = @command.inputs[name]

      val =
        if meta[:default].respond_to? :to_proc
          @context.instance_exec(*args, &meta[:default])
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
    end
  end
end
