class Mothership
  class Parser
    def initialize(command)
      @command = command
    end

    def inputs(argv)
      inputs = {}

      args = parse_flags(inputs, argv.dup)

      parse_arguments(inputs, args)

      inputs
    end

    def parse_flags(inputs, argv, find_in = nil)
      local = nil
      args = []

      until argv.empty?
        flag = normalize_flag(argv.shift, argv)

        name = local && local.flags[flag] || @command.flags[flag]
        unless name
          # assume first argument is subcommand
          if args.empty? && find_in && !local
            local = find_in[flag.to_sym]
          end

          args << flag
          next
        end

        # skip flags defined by the local cmd
        if local && local.inputs[name]
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
            raise TypeMismatch.new(@command.name, name, "floating")
          end
        when :integer, :number, :numeric
          if !argv.empty? && argv.first =~ /^[0-9]+$/
            inputs[name] = argv.shift.to_i
          else
            raise TypeMismatch.new(@command.name, name, "numeric")
          end
        else
          if argv.empty? || !argv.first.start_with?("-")
            arg = argv.shift || ""

            inputs[name] =
              if input[:argument] == :splat
                arg.split(",")
              else
                arg
              end
          end
        end
      end

      args
    end

    # [FOO] [BAR] FIZZ BUZZ:
    #   1 2 => :fizz => 1, :buzz => 2
    #   1 2 3 => :foo => 1, :fizz => 2, :buzz => 3
    #   1 2 3 4 => :foo => 1, :bar => 2, :fizz => 3, :buzz => 4
    def parse_arguments(inputs, args)
      total = @command.arguments.size
      required = 0
      optional = 0
      @command.arguments.each do |arg|
        case arg[:type]
        when :optional
          optional += 1
        when :splat
          break
        else
          required += 1
        end
      end

      parse_optionals = args.size - required

      @command.arguments.each do |arg|
        name = arg[:name]
        next if inputs.key? name

        case arg[:type]
        when :splat
          inputs[name] = []

          until args.empty?
            inputs[name] << args.shift
          end

        when :optional
          if parse_optionals > 0 && val = args.shift
            inputs[name] = val
            parse_optionals -= 1
          end

        else
          if val = args.shift
            inputs[name] = val
          elsif !@command.inputs[name][:default]
            raise MissingArgument.new(@command.name, name)
          end
        end
      end

      raise ExtraArguments.new(@command.name, args) unless args.empty?
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
end
