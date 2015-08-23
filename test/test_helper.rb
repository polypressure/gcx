$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'simplecov'
SimpleCov.start do
  add_filter "/test/"
end

require 'gcx'

require 'minitest/autorun'
require 'minitest/pride'

require "minitest/reporters"
Minitest::Reporters.use!(
  Minitest::Reporters::SpecReporter.new,
  ENV,
  Minitest.backtrace_filter
)

#
# Allow for Rails-style test names, where test names can be defined with
# strings rather than a Ruby-method name with underscores.
#
# Usage:
#
#   class
#     extend DefineTestNamesWithStrings
#     ...
#     test "a descriptive test name" do
#       ...
#     end
#   end
#
# Note: We could have just pulled this in from ActiveSupport::TestCase,
# but I wanted to avoid the dependency.
#
module DefineTestNamesWithStrings

  #
  # Helper to define a test method using a String. Under the hood, it replaces
  # spaces with underscores and defines the test method.
  #
  #   test "verify something" do
  #     ...
  #   end
  #
  def test(name, &block)
    test_name = "test_#{name.gsub(/\s+|,/,'_')}".to_sym
    defined = method_defined? test_name
    raise "#{test_name} is already defined in #{self}" if defined
    if block_given?
      define_method(test_name, &block)
    else
      define_method(test_name) do
        flunk "No implementation provided for #{name}"
      end
    end
  end
end

module Minitest
  class Test
    extend DefineTestNamesWithStrings

    #
    # Reset key-value store to the starting state.
    #
    def reset_model_store!
      GCX::Model.clear_all!
      GCX::Account.create_house_account
    end

    #
    # Assert that the given block raises the specified error,
    # and that the error's message matches the given regex.
    #
    def assert_raises_with_message(error_class, message_pattern, &block)
      error = assert_raises(error_class, &block)
      assert_match message_pattern, error.message
    end

  end
end

require 'mocha/mini_test'
