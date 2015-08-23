require 'test_helper'

#
# Tests to verify the Command object dispatches commands and logs
# errors correctly. These tests are isolated, at the usual cost
# of some mocking.
#
module GCX
  class CommandTest < Minitest::Test

    #
    # Basic parsing and dispatching of commands.
    #
    test "dispatches a valid add_account command with no commission arg" do
      Account.expects(:add).with('Bob')

      Command.new('add_account Bob').execute
    end

    test "dispatches a valid add_account command with a commission arg" do
      Account.expects(:add).with('Alice', '0.20')

      Command.new('add_account Alice 0.20').execute
    end

    test "dispatches a valid list_product command" do
      Product.expects(:list).with('Bill', 'Sears', '0234512345', '$119.58', '$105.00')

      Command.new('list_product Bill Sears 0234512345 $119.58 $105.00').execute
    end

    test "dispatches a valid buy_product command" do
      Product.expects(:buy).with('Sally', 'hm.com', '8180325123')

      Command.new('buy_product Sally hm.com 8180325123').execute
    end

    test "Command.process processes a line" do
      Account.expects(:add).with('Alice', '0.20')

      Command.process('add_account Alice 0.20')
    end


    #
    # Parsing atypical but valid commands.
    #

    test "parses double-quoted arguments containing spaces" do
      Product.expects(:buy).with('Sally', 'The North Face', '8180325123')

      Command.new('buy_product Sally "The North Face" 8180325123').execute
    end

    test "parses double-quoted arguments containing single quote" do
      Product.expects(:buy).with('Sally', "Kohl's", '8180325123')

      Command.new(%q{buy_product Sally "Kohl's" 8180325123}).execute
    end

    test "parses a command line with leading/trailing spaces" do
      Product.expects(:buy).with('Sally', 'Amazon', '8180325123')

      Command.new('  buy_product Sally Amazon 8180325123    ').execute
    end


    #
    # Error logging...
    #

    test "invalid command logs error" do
      STDERR.expects(:puts).with("test-input.txt:25 - Invalid command by_product")

      Command.new('by_product Sally hm.com 8180325123').execute("test-input.txt", 25)
    end

    test "logs errors raised by model objects" do
      STDERR.expects(:puts).
        with("test-input.txt:215 - Product not found with key: [\"Amazon\", \"1234512345\"]")
      Product.stubs(:[]).raises(ArgumentError, "Product not found with key: [\"Amazon\", \"1234512345\"]" )

      Command.new('buy_product Sally Amazon 1234512345').execute("test-input.txt", 215)
    end


    #
    # Other...
    #

    test "Command.configure sets configuration options" do
      Command.configure(abort_on_error: true)
      assert Command.abort_on_error?

      Command.configure(abort_on_error: false)
      refute Command.abort_on_error?
    end

  end
end
