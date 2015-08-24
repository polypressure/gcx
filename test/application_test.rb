require 'test_helper'

#
# Tests to verify the Application object processes its command-line
# args and options properly. Other than reading from a small file
# which wasn't worth mocking, these tests are isolated.
#
module GCX
  class ApplicationTest < Minitest::Test

    test "Running with no args processes STDIN" do
      STDIN.expects(:each_line).returns([])
      Account.stubs(:summary).returns([])

      Application.new([]).run
    end

    test "Running with args processes each file" do
      File.expects(:open).with("foo.txt")
      File.expects(:open).with("bar.txt")
      File.expects(:open).with("baz.txt")
      Account.stubs(:summary).returns([])

      Application.new(["foo.txt", "bar.txt", "baz.txt"]).run
    end

    test "Processes each line" do
      lines = File.readlines("test/fixtures/simple-input-1.txt")
      lines.each_with_index do |line, n|
        Command.expects(:process).with(line, "test/fixtures/simple-input-1.txt", n+1)
      end
      Account.stubs(:summary).returns([])

      Application.new(["test/fixtures/simple-input-1.txt"]).run
    end

    test "displays progress bar when -p option is given" do
      ProgressBar.expects(:create).returns(mock_pbar = mock)
      mock_pbar.expects(:increment).at_least_once

      Application.new(["-p", "test/fixtures/simple-input-1.txt"]).run
    end
  end
end
