class Mothership::Inputs
  attr_reader :inputs

  def initialize(command, context, inputs = {})
    @command = command
    @context = context
    @inputs = inputs
    @cache = {}
  end

  def [](name, *args)
    return @inputs[name] if @inputs.key? name
    return @cache[name] if @cache.key? name

    meta = @command.inputs[name]

    val =
      if meta[:default]
        @context.instance_exec(*args, &meta[:default])
      elsif meta[:type] == :boolean
        false
      end

    unless meta[:forget]
      @cache[name] = val
    end

    val
  end
end
