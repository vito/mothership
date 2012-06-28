class Mothership::Parser
  def initialize(command)
    @command = command
  end

  def inputs(argv)
    inputs = {}

    args = parse_flags(inputs, argv.dup)

    parse_arguments(inputs, args)

    inputs
  end

  def parse_flags(inputs, argv)
    args = []

    until argv.empty?
      flag = normalize_flag(argv.shift, argv)

      name = @command.flags[flag]
      unless name
        #if flag.start_with?("-")
          #raise "unknown flag: #{flag}"
        #end

        args << flag
        next
      end

      input = @command.inputs[name]

      case input[:type]
      when :bool, :boolean
        if argv.first == "false" || argv.first == "true"
          inputs[name] = argv.shift == "true"
        else
          inputs[name] = true
        end
      when :float, :floating
        if !argv.empty? && argv.first =~ /^[0-9]+(\.[0-9]*)?$/
          inputs[name] = argv.shift.to_f
        else
          raise "expected floating value for #{name}"
        end
      when :integer, :number, :numeric
        if !argv.empty? && argv.first =~ /^[0-9]+$/
          inputs[name] = argv.shift.to_i
        else
          raise "expected numeric value for #{name}"
        end
      else
        if argv.empty? || !argv.first.start_with?("-")
          arg = argv.shift || ""

          inputs[name] =
            if input[:argument] && input[:argument][:splat]
              arg.split(",")
            else
              arg
            end
        end
      end
    end

    args
  end

  def parse_arguments(inputs, args)
    @command.arguments.each do |arg|
      name = arg[:name]
      next if inputs.key? name

      if arg[:splat]
        inputs[name] = []

        until args.empty?
          inputs[name] << args.shift
        end

      elsif val = args.shift
        inputs[name] = val

      elsif !(arg[:optional] || @command.inputs[name][:default])
        raise "missing required argument '#{name}'"
      end
    end

    raise "too many arguments" unless args.empty?
  end

  private

  # --no-foo => --foo false
  # --no-foo true => --foo false
  # --no-foo false => --foo true
  #
  # --foo=bar => --foo bar
  def normalize_flag(flag, argv)
    case flag
    # boolean negation
    when /^--no-(.+)/
      case argv.first
      when "true"
        argv[0] = "false"
      when "false"
        argv[0] = "true"
      else
        argv.unshift "false"
      end

      "--#$1"

    # --foo=bar form
    when /^--([^=]+)=(.+)/
      argv.unshift $2
      "--#$1"

    # normal flag name
    when /^--([^ ]+)$/
      "--#$1"

    else
      flag
    end
  end
end
