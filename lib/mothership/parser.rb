class Mothership
  class Parser
    attr_reader :given

    def initialize(command, given = {})
      @command = command
      @given = given
    end

    def parse_argv(argv)
      args = parse_flags(argv.dup)

      parse_arguments(args)

      @given
    end

    def parse_flags(argv, find_in = nil)
      local = nil
      args = []

      until argv.empty?
        flag = normalize_flag(argv.shift, argv)

        name = local && local.flags[flag] || @command.flags[flag]
        unless name
          # assume first argument is subcommand
          if args.empty? && find_in && !local
            local = find_in[flag.gsub("-", "_").to_sym]
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

        if argv.first == "--ask"
          @given[name] = :interact
          argv.shift
          next
        end

        case input[:type]
        when :bool, :boolean
          if argv.first == "false" || argv.first == "true"
            @given[name] = argv.shift
          else
            @given[name] = "true"
          end
        when :float, :floating
          if !argv.empty? && argv.first =~ /^[0-9]+(\.[0-9]*)?$/
            @given[name] = argv.shift
          else
            raise TypeMismatch.new(@command, name, "floating")
          end
        when :integer, :number, :numeric
          if !argv.empty? && argv.first =~ /^[0-9]+$/
            @given[name] = argv.shift
          else
            raise TypeMismatch.new(@command, name, "numeric")
          end
        else
          arg =
            if argv.empty? || argv.first.start_with?("-")
              ""
            else
              argv.shift
            end

          @given[name] =
            if input[:argument] == :splat
              arg.split(",")
            else
              arg
            end
        end
      end

      args
    end

    # [FOO] [BAR] FIZZ BUZZ:
    #   1 2 => :fizz => 1, :buzz => 2
    #   1 2 3 => :foo => 1, :fizz => 2, :buzz => 3
    #   1 2 3 4 => :foo => 1, :bar => 2, :fizz => 3, :buzz => 4
    def parse_arguments(args)
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
        next if @given.key? name

        input = @command.inputs[name]

        case arg[:type]
        when :splat
          @given[name] = []

          until args.empty?
            @given[name] << args.shift
          end

        when :optional
          if parse_optionals > 0 && val = args.shift
            @given[name] = val
            parse_optionals -= 1
          end

        else
          if val = args.shift
            @given[name] = val
          elsif !input[:default] && !input[:interact]
            raise MissingArgument.new(@command, name)
          end
        end
      end

      raise ExtraArguments.new(@command, args) unless args.empty?
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

      when /^--ask-(.+)/
        argv.unshift "--ask"
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
