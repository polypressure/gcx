require 'test_helper'
require "open3"

#
# High-level acceptance tests for the giftcard_market executable,
# fully-integrated system test of course.
#
class GiftcardMarketTest < Minitest::Test

  test "processes simple input from STDIN" do
    expected_stdout = File.read('test/fixtures/expected-output/simple-stdout-1.txt')

    cmd = "bin/giftcard_market < test/fixtures/simple-input-1.txt"
    actual_stdout, actual_stderr, status = Open3.capture3(cmd)

    assert_equal expected_stdout, actual_stdout
    assert_equal "", actual_stderr
    assert_equal 0, status
  end

  test "processes file given on command line" do
    expected_stdout = File.read('test/fixtures/expected-output/simple-stdout-2.txt')

    cmd = "bin/giftcard_market test/fixtures/simple-input-2.txt"
    actual_stdout, actual_stderr, status = Open3.capture3(cmd)

    assert_equal expected_stdout, actual_stdout
    assert_equal "", actual_stderr
    assert_equal 0, status
  end

  test "processes multiple files given as command-line args" do
    expected_stdout = File.read('test/fixtures/expected-output/simple-stdout-1-and-2.txt')

    cmd = "bin/giftcard_market test/fixtures/simple-input-1.txt test/fixtures/simple-input-2.txt"
    actual_stdout, actual_stderr, status = Open3.capture3(cmd)

    assert_equal expected_stdout, actual_stdout
    assert_equal "", actual_stderr
    assert_equal 0, status
  end

  test "logs errors to stderr without aborting" do
    expected_stdout = File.read('test/fixtures/expected-output/errors-stdout.txt')
    expected_stderr = File.read('test/fixtures/expected-output/errors-stderr.txt')

    cmd = "bin/giftcard_market test/fixtures/input-with-errors.txt"
    actual_stdout, actual_stderr, status = Open3.capture3(cmd)

    assert_equal expected_stdout, actual_stdout
    assert_equal expected_stderr, actual_stderr
    assert_equal 0, status
  end

  test "aborts immediately on errors if -a option is given" do
    expected_stdout = ""
    expected_stderr = "ABORTING - test/fixtures/input-with-errors.txt:2 - Invalid command add_acount"

    cmd = "bin/giftcard_market -a test/fixtures/input-with-errors.txt"
    actual_stdout, actual_stderr, status = Open3.capture3(cmd)

    assert_equal expected_stdout, actual_stdout.chomp
    assert_equal expected_stderr, actual_stderr.chomp
    refute_equal 0, status
  end

  test "processes big complicated file" do
    skip
  end

end
