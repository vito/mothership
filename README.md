Mothership
==========

This gem is for defining a big honkin' extensible command-line application.

It's similar to Thor, but instead of focusing on having multiple composable
command sets, there's simply a global command set that can be trivially
extended while keeping the extensions isolated.

Commands are defined in subclasses of `Mothership`. Because commands are
isolated into their own classes, helper methods and constants can be safely
defined in it without risking a name collision with other extensions.

All inputs for a command are defined declaratively. They all have a name,
which is used for the flag name, and a few options that I'll go over later.

In a more 'functional' style, commands take all of their inputs as a single
argument, rather than having the inputs embedded in a stateful object. This
makes it easier for one command to invoke another with a given set of inputs,
without risking any sort of collision based on their input names.

For example, to define a 'insult' command which insults the user, with an
optional censoring flag:

    class Insults < Mothership
      desc "Insults the user."
      input :censor, :type => :boolean, :alias => "-c"
      def insult
        puts "Hey man, #{curse_word(input[:censored])} you."
      end

      private

      def curse_word(censor = false)
        if censor
          "$%#^*"
        else
          "foo"
        end
      end
    end

When the 'insult' command is defined, it is registered in `CommandSet`. When
the user invokes 'insult', the `Insults` class is instantiated, the inputs are
parsed, and the `insult` method is called with the given inputs as a hash-like
object.

A default value may be provided for an input by calling it with a block that
gets called when the value is requested but not provided by the user:

    input(:name) { ask("What's your name?") }

The block is called on the instance of the object, the first time you try to
do `input[:foo]`. To pass values to the block, you can do `input[:foo, arg1,
...]`.

The returned value is cached, so you can just use `input[:name]` to access the
value, and it will only ask the first time. Full example:

    desc "Delete something."
    input(:name) { ask("Delete what?") }
    input(:really) { |name| ask("Really delete #{name}?") }
    def delete(input)
      return unless input[:really, input[:name]]

      puts "BAM, #{input[:name]} is gone forever."
    end

    # => myapp delete
    #    Delete what?> foo
    #    Really delete foo?> y
    #    BAM, foo is gone forever.

An input can be accepted in an argument or splat-argument form by passing
`:argument => true` or `:argument => :splat`:

    desc "Deleting something with the given reasons, if any."
    input :name, :argument => true
    input :reasons, :argument => :splat, :alias => "--reason"
    def delete(input)
      puts "Deleting #{input[:name]} because: #{input[:reasons].join ", "}"
    end

This will accept the following forms:

    delete foo bar baz
    delete --name foo bar baz
    delete --name foo --reasons bar,baz
    delete --name foo --reason bar,baz
    delete bar baz --name foo
    delete foo --reasons bar,baz
    delete foo --reason bar,baz

Note that that "--reason" alias accepts the more natural "--reason foo" for
when there is only a single reason. Also note that flags are parsed before
arguments, so it doesn't matter if they're tacked on to the end or if they
appear before them.

Because both flags and arguments are defined with the same mechanic, the usage
string for a command can be auto-generated based on its input metadata, rather
than being hardcoded and possibly becoming inaccurate if a plugin changes the
input structure. For example, a command 'foo' with an optional argument `:bar`
and a splat argument `:bazes` will have a usage string of `foo BAR BAZES...`.
