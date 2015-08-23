require 'test_helper'

#
# Test the Account model's methods for saving/adding accounts,
# validation/parsing/formatting, fetching the house account,
# crediting/debiting balances, and producing an account summary.
#
# These tests interact with the key-value store, so strictly-speaking,
# they aren't isolated. However, since the key-value store is simple
# and in-memory by default, these tests are not necessarily integrated
# in the same sense as an ActiveRecord model.
#
module GCX
  class AccountTest < Minitest::Test

    def setup
      reset_model_store!
    end


    #
    # Adding accounts...
    #

    test "adds an Account with default commission_rate when only name given" do
      Account.add("Bob")

      assert_equal "Bob", Account["Bob"].name
    end

    test "adds an Account when already added doesn't overwrite" do
      Account.add("Bob")
      Account['Bob'].credit!("50")

      Account.add("Bob")

      assert_equal Monetize.parse("50"), Account["Bob"].balance
    end


    #
    # Commission rate parsing...
    #

    test "adds an Account when name and commission_rate given" do
      Account.add("Bob", "0.18")

      assert_equal "Bob", Account["Bob"].name
      assert_equal BigDecimal.new("0.18"), Account["Bob"].commission_rate
    end

    test "adds an Account with commission_rate of 0" do
      Account.add("Bob", "0")

      assert_equal BigDecimal.new("0"), Account["Bob"].commission_rate
    end

    test "adds an Account with commission_rate of 0.0" do
      Account.add("Bob", "0.0")

      assert_equal BigDecimal.new("0"), Account["Bob"].commission_rate
    end

    test "adds an Account with commission_rate of 1" do
      Account.add("Bob", "1")
      assert_equal BigDecimal.new("1"), Account["Bob"].commission_rate
    end

    test "adds an Account with commission_rate of 1.0" do
      Account.add("Bob", "1.0")

      assert_equal BigDecimal.new("1"), Account["Bob"].commission_rate
    end

    test "adds an Account with commission_rate of one decimal place" do
      Account.add("Bob", "0.1")

      assert_equal BigDecimal.new("0.1"), Account["Bob"].commission_rate
    end


    #
    # Parsing/scrubbing name...
    #

    test "strips leading/trailing and consecutive internal spaces from name" do
      account = Account.add("   Billy  Bob    ")

      assert_equal "Billy Bob", account.name
    end


    #
    # Validation errors...
    #

    test "raises error when adding account with extra args" do
      assert_raises_with_message(ArgumentError, /wrong number of arguments/) {
        Account.add("Alice", "0.20", "123")
      }
    end

    test "raises error when adding account with blank or nil name" do
      assert_raises_with_message(ArgumentError, /name.+required/) {
        Account.add("")
      }

      assert_raises_with_message(ArgumentError, /name.+required/) {
        Account.add(nil)
      }
    end

    test "raises error when adding account with an invalid commission_rate" do
      assert_raises_with_message(ArgumentError, /commission_rate/) {
        Account.add("Alice", "0a12")
      }
    end

    test "raises error when adding account with a commission_rate out of range" do
      assert_raises_with_message(ArgumentError, /commission_rate/) {
        Account.add("Alice", "1.01")
      }
    end

    test "raises error when adding account with a commission_rate without leading zero" do
      assert_raises_with_message(ArgumentError, /commission_rate/) {
        Account.add("Alice", ".18")
      }
    end

    test "raises error when adding account with a commission_rate with more than 2 decimal places" do
      assert_raises_with_message(ArgumentError, /commission_rate/) {
        Account.add("Alice", ".183")
      }
    end


    #
    # House account...
    #

    test "Raise house account is created" do
      assert_equal "Raise", Account.house_account.name
      assert_equal BigDecimal.new("0.15"), Account.house_account.commission_rate
    end


    #
    # Credit and debit...
    #

    test "credit! adds the specified amount to the balance" do
      Account.add("Bob")
      assert_equal Monetize.parse("0"), Account["Bob"].balance

      Account["Bob"].credit!("85.50")
      assert_equal Monetize.parse("85.50"), Account["Bob"].balance

      Account["Bob"].credit!("18.23")
      assert_equal Monetize.parse("103.73"), Account["Bob"].balance
    end

    test "debit! adds the specified amount to the balance" do
      Account.add("Bob")
      Account["Bob"].credit!("100.00")
      assert_equal Monetize.parse("100"), Account["Bob"].balance

      Account["Bob"].debit!("48.70")
      assert_equal Monetize.parse("51.30"), Account["Bob"].balance

      Account["Bob"].debit!("91.23")
      assert_equal Monetize.parse("-39.93"), Account["Bob"].balance
    end


    #
    # Formatting balance as dollar amount...
    #

    test "formatted_balance formats positive balance" do
      Account.add("Bob")
      Account["Bob"].credit!("75.26")

      assert_equal "$75.26", Account["Bob"].formatted_balance
    end

    test "formatted_balance formats negative balance" do
      Account.add("Bob")
      Account["Bob"].credit!("-15.38")

      assert_equal "-$15.38", Account["Bob"].formatted_balance
    end

    test "formatted_balance formats round balance balance padded" do
      Account.add("Bob")
      Account["Bob"].credit!("7")

      assert_equal "$7.00", Account["Bob"].formatted_balance
    end

    test "formatted_balance formats large balances" do
      Account.add("Bob")
      Account["Bob"].credit!("85783580")

      assert_equal "$85,783,580.00", Account["Bob"].formatted_balance
    end


    #
    # Account summary...
    #

    test "account summary shows only Raise account when no accounts added" do
      assert_equal ["Raise $0.00"], Account.summary
    end

    test "account summary shows correct balances and sorted alpha with Raise account at bottom" do
      Account.add("Zachary")
      Account["Zachary"].debit!("76.85")
      Account.add("Bob")
      Account["Bob"].credit!("50.68")
      Account.add("Alice")
      Account["Alice"].debit!("23.15")
      Account.add("Hakeem")
      Account["Hakeem"].credit!("10000")
      Account.house_account.credit!("338.97")

      assert_equal ["Alice -$23.15",
                    "Bob $50.68",
                    "Hakeem $10,000.00",
                    "Zachary -$76.85",
                    "Raise $338.97"], Account.summary
    end


    #
    # Clear store...
    #

    test "Account.clear_all! raises exception" do
      assert_raises_with_message(RuntimeError, /Model\.clear_all/) {
        Account.clear_all!
      }
    end

  end

end
