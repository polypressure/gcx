require 'test_helper'

#
# Test the Product model's smethods for saving/adding products,
# validation/parsing/formatting, listing and purchasing products,
# fetching the product seller's account, and computing commisions
# seller's share from sale proceeds.
#
# These tests interact with the key-value store, so strictly-speaking,
# they aren't isolated. However, since the key-value store is simple
# and in-memory by default, these tests are not necessarily integrated
# in the same sense as an ActiveRecord model.
#
module GCX
  class ProductTest < Minitest::Test

    def setup
      reset_model_store!
    end

    #
    # Listing products...
    #

    test "lists a product given valid arguments" do
      Account.add("Alice")

      Product.list("Alice", "Amazon.com", "1234512345", "$100.00", "$90.00")

      product = Product["Amazon.com", "1234512345"]
      assert_equal "Alice", product.seller_name
      assert_equal "Amazon.com", product.brand
      assert_equal "1234512345", product.card_id
      assert_equal Monetize.parse("100"), product.value
      assert_equal Monetize.parse("90"), product.price
    end

    test "lists a product with value and price containing commas" do
      Account.add("Alice")

      Product.list("Alice", "Amazon.com", "1234512345", "$1,100.00", "$1,090.50")

      product = Product["Amazon.com", "1234512345"]
      assert_equal "Alice", product.seller_name
      assert_equal "Amazon.com", product.brand
      assert_equal "1234512345", product.card_id
      assert_equal Monetize.parse("1100"), product.value
      assert_equal Monetize.parse("1090.50"), product.price
    end

    test "list an existing product raises an exception" do
      Account.add("Alice")
      Account.add("Bob")

      Product.list("Alice", "Amazon.com", "1234512345", "$1,100.00", "$1,090.50")
      assert_raises_with_message(ArgumentError, /Product.+already listed/) {
        Product.list("Bob", "Amazon.com", "1234512345", "$1,100.00", "$1,090.50")
      }
    end


    #
    # Validating seller...
    #

    test "raises error when listing product and seller does not exist" do
      assert_raises_with_message(ArgumentError, /seller_name.+not found/) {
        Product.list("Alice", "Amazon.com", "1234512345", "$100.00", "$90.00")
      }
    end

    test "raises error when listing product and seller is blank or nil" do
      assert_raises_with_message(ArgumentError, /seller_name.+required/) {
        Product.list("", "Amazon.com", "1234512345", "$100.00", "$90.00")
      }

      assert_raises_with_message(ArgumentError, /seller_name.+required/) {
        Product.list(nil, "Amazon.com", "1234512345", "$100.00", "$90.00")
      }
    end


    #
    # Validating brand...
    #

    test "raises error when listing product and brand is blank or nil" do
      assert_raises_with_message(ArgumentError, /brand.+required/) {
        Product.list("Alice", "", "1234512345", "$100.00", "$90.00")
      }

      assert_raises_with_message(ArgumentError, /brand.+required/) {
        Product.list("Alice", nil, "1234512345", "$100.00", "$90.00")
      }
    end


    #
    # Valdating card ID...
    #

    test "raises error when listing product and card_id is blank or nil" do
      assert_raises_with_message(ArgumentError, /card ID/) {
        Product.list("Alice", "Amazon.com", "", "$100.00", "$90.00")
      }

      assert_raises_with_message(ArgumentError, /card ID/) {
        Product.list("Alice", "Amazon.com", nil, "$100.00", "$90.00")
      }
    end

    test "raises error when listing product and card_id is not 10-digit string" do
      assert_raises_with_message(ArgumentError, /card ID/) {
        Product.list("Alice", "Amazon.com", "123", "$100.00", "$90.00")
      }

      assert_raises_with_message(ArgumentError, /card ID/) {
        Product.list("Alice", "Amazon.com", "12345678901", "$100.00", "$90.00")
      }

      assert_raises_with_message(ArgumentError, /card ID/) {
        Product.list("Alice", "Amazon.com", "123abc123d", "$100.00", "$90.00")
      }
    end


    #
    # Validating price...
    #

    test "raises error when listing product and price is not positive" do
      Account.add("Alice")

      assert_raises_with_message(ArgumentError, /price.+more than \$0/) {
        Product.list("Alice", "Amazon.com", "1234512345", "$100.00", "-$90.00")
      }

      assert_raises_with_message(ArgumentError, /price.+more than \$0/) {
        Product.list("Alice", "Amazon.com", "1234512345", "$100.00", "$0.00")
      }
    end

    test "raises error when listing product and price is an invalid dollar value" do
      Account.add("Alice")

      assert_raises_with_message(ArgumentError, /price.+valid dollar value/) {
        Product.list("Alice", "Amazon.com", "1234512345", "$85.00", "f10f0.00")
      }

      assert_raises_with_message(ArgumentError, /price.+valid dollar value/) {
        Product.list("Alice", "Amazon.com", "1234512345", "$85.00", "20.00")
      }

      assert_raises_with_message(ArgumentError, /price.+valid dollar value/) {
        Product.list("Alice", "Amazon.com", "1234512345", "$85.00", "20.0")
      }

      assert_raises_with_message(ArgumentError, /price.+valid dollar value/) {
        Product.list("Alice", "Amazon.com", "1234512345", "$85.00", "20.001")
      }

      assert_raises_with_message(ArgumentError, /price.+valid dollar value/) {
        Product.list("Alice", "Amazon.com", "1234512345", "$85.00", "20")
      }
    end


    #
    # Validating value...
    #

    test "raises error when listing product and value is not positive" do
      Account.add("Alice")

      assert_raises_with_message(ArgumentError, /value.+more than \$0/) {
        Product.list("Alice", "Amazon.com", "1234512345", "-$100.00", "$90.00")
      }

      assert_raises_with_message(ArgumentError, /value.+more than \$0/) {
        Product.list("Alice", "Amazon.com", "1234512345", "$0.00", "$90.00")
      }
    end

    test "raises error when listing product and value is an invalid dollar value" do
      Account.add("Alice")

      assert_raises_with_message(ArgumentError, /value.+valid dollar value/) {
        Product.list("Alice", "Amazon.com", "1234512345", "f10f0.00", "$90.00")
      }

      assert_raises_with_message(ArgumentError, /value.+valid dollar value/) {
        Product.list("Alice", "Amazon.com", "1234512345", "20.00", "$90.00")
      }

      assert_raises_with_message(ArgumentError, /value.+valid dollar value/) {
        Product.list("Alice", "Amazon.com", "1234512345", "20.0", "$90.00")
      }

      assert_raises_with_message(ArgumentError, /value.+valid dollar value/) {
        Product.list("Alice", "Amazon.com", "1234512345", "20.001", "$90.00")
      }

      assert_raises_with_message(ArgumentError, /value.+valid dollar value/) {
        Product.list("Alice", "Amazon.com", "1234512345", "20", "$90.00")
      }
    end

    test "raises error when the sale price isn't less than the card value" do
      Account.add("Alice")

      assert_raises_with_message(ArgumentError, /value .+ more than price/) {
        Product.list("Alice", "Amazon.com", "1234512345", "$85.00", "$100.00")
      }

      assert_raises_with_message(ArgumentError, /value .+ more than price/) {
        Product.list("Alice", "Amazon.com", "1234512345", "$85.00", "$85.00")
      }
    end


    #
    # Fetching seller...
    #

    test "can fetch seller" do
      Account.add("Alice")
      Product.list("Alice", "Amazon.com", "1234512345", "$185.00", "$100.00")

      assert_equal Account["Alice"], Product["Amazon.com", "1234512345"].seller
    end


    #
    # Computing commission and seller's share...
    #

    test "computes house commission" do
      Account.add("Alice")
      Product.list("Alice", "Amazon.com", "1234512345", "$110.00", "$100.00")

      assert_equal Monetize.parse("$15"), Product["Amazon.com", "1234512345"].house_commission

      Account.add("Bob", "0.20")
      Product.list("Bob", "Whole Foods", "8888877777", "$110.00", "$100.00")

      assert_equal Monetize.parse("$20"), Product["Whole Foods", "8888877777"].house_commission
    end

    test "computes seller's share" do
      Account.add("Alice")
      Product.list("Alice", "Amazon.com", "1234512345", "$110.00", "$100.00")

      assert_equal Monetize.parse("$85"), Product["Amazon.com", "1234512345"].sellers_share

      Account.add("Bob", "0.20")
      Product.list("Bob", "Whole Foods", "8888877777", "$110.00", "$100.00")

      assert_equal Monetize.parse("$80"), Product["Whole Foods", "8888877777"].sellers_share
    end


    #
    # Buying a product...
    #

    test "Product#buy completes purchase of product" do
      Account.add("Buyer")
      Account.add("Seller")
      Product.list("Seller", "Whole Foods", "8888877777", "$110.00", "$100.00")

      Product["Whole Foods", "8888877777"].buy("Buyer")

      assert_nil Product.fetch("Whole Foods", "8888877777")
      assert_equal Monetize.parse("-100"), Account["Buyer"].balance
      assert_equal Monetize.parse("15"), Account.house_account.balance
      assert_equal Monetize.parse("85"), Account["Seller"].balance
    end

    test "Product.buy_product completes purchase of product" do
      Account.add("Buyer")
      Account.add("Seller")
      Product.list("Seller", "Whole Foods", "8888877777", "$110.00", "$100.00")

      Product.buy("Buyer", "Whole Foods", "8888877777")

      assert_nil Product.fetch("Whole Foods", "8888877777")
      assert_equal Monetize.parse("-100"), Account["Buyer"].balance
      assert_equal Monetize.parse("15"), Account.house_account.balance
      assert_equal Monetize.parse("85"), Account["Seller"].balance
    end


    #
    # Clear store all...
    #

    test "Product.clear_all! raises exception" do
      assert_raises_with_message(RuntimeError, /Model\.clear_all/) {
        Product.clear_all!
      }
    end

  end
end
