require 'moneta'
require 'bigdecimal'

#
# Given a line from an input file, parse and execute it,
# delegating the details of the work to the Accound and Product
# model objects.
#
# Errors are log to STDERR, with the offending line numbers from
# the input file. File processing continues when errors are
# encountered, unless the abort_on_error option has been set.
#
module GCX
  class Command

    #
    # Set any config options parsed from the command line.
    #
    def self.configure(options)
      @options = options
    end

    #
    # Initialize with a line from the input file.
    #
    def initialize(line)
      @line = line
    end

    #
    # Parse and execute the line.
    #
    def execute(filename="stdio", line_number=0)
      command, *args = @line.shellsplit
      COMMANDS.fetch(command.to_sym).call(args)
    rescue KeyError => err
      log_error(filename, line_number, "Invalid command #{command}")
    rescue => err
      log_error(filename, line_number, err.message)
    end

    def self.process(line, filename="stdio", line_number=0)
      Command.new(line).execute(filename, line_number)
    end


    private

    #
    # Log errors to STDERR, annotated with offending filename and line number.
    #
    def log_error(filename, line_number, message)
      numbered_message = "#{filename}:#{line_number} - #{message}"
      if Command.abort_on_error?
        abort "ABORTING - #{numbered_message}"
      else
        STDERR.puts numbered_message
      end
    end

    #
    # Check if the abort_on_error option is set. Defaults to false.s
    #
    def self.abort_on_error?
      @options ||= { abort_on_error: false }
      @options[:abort_on_error]
    end

    #
    # Hash of lambdas when a case statement would have sufficed, but you know.
    # Also could have done it dynamically with Object#send, but unsafe
    # unless you filter/blacklist the method/message names.
    #
    COMMANDS = {
      add_account: ->(args) { Account.add(*args) },
      list_product: ->(args) { Product.list(*args) },
      buy_product: ->(args) { Product.buy(*args) }
    }
  end

end
