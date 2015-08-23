#
# Represents a product/card in the marketplace, with seller_name,
# and card brand, ID, value and price attributes.
#
# Also provides methods to determine the seller's share and Raise's
# commision upon purchase, lookup the seller, and to complete
# a purchase.
#
module GCX
  class Product < Model

    attr_accessor :seller_name, :brand, :card_id, :value, :price

    #
    # Initialize a new Product.
    #
    # Raises an error if:
    #  - seller_name is blank
    #  - brand is blank
    #  - card_id is blank or is not a 10-digit string
    #  - value is not a valid numeric/dollar value
    #  - price is not a valid numeric/dollar value
    #  - value is not greater than price
    #  - value is not positive
    #  - price is not positive
    #
    def initialize(seller_name:, brand:, card_id:, value:, price:)
      set_required_field(:seller_name, seller_name)
      set_required_field(:brand, brand)
      set_card_id_field(:card_id, card_id)
      set_monetary_field(:value, value)
      set_monetary_field(:price, price)

      verify_positive_value!
      verify_positive_price!
      verify_value_exceeds_price!
      verify_seller_exists!
    end

    #
    # An Product's lookup key consists of the brand and card_id.
    #
    def keys
      [brand, card_id]
    end

    #
    # Make a product/giftcard with the given attributes available
    # for sale on the marketplace.
    #
    # Raises an error if the seller doesn't exist in the
    # marketplace
    #
    def self.list(seller_name, brand, card_id, value, price)
      if Product.fetch(brand, card_id)
        raise ArgumentError, "Product[#{brand}, #{card_id}] already listed"
      end

      product = new(
        seller_name: seller_name,
        brand: brand,
        card_id: card_id,
        value: value,
        price: price
      )

      product.store
    end

    #
    # Complete a purchase of the specified product
    # by the given buyer.
    #
    # Raises an error if the buyer doesn't exist in the
    # marketplace.
    #
    def self.buy(buyer_name, brand, card_id)
      Product[brand, card_id].buy(buyer_name)
    end

    #
    # Complete a purchase of the product from the marketplace
    # by the specified buyer.
    #
    # Raises an error if the buyer doesn't exist in the
    # marketplace.
    #
    def buy(buyer_name)
      Account[buyer_name].debit!(price)
      Account["Raise"].credit!(house_commission)
      seller.credit!(sellers_share)

      self.delete!
    end

    #
    # Lookup the product seller's account.
    # Raises an error if the account can't be found.
    #
    def seller
      Account[seller_name]
    end

    #
    # Compute the portion of the product's sale proceeds that
    # Raise keeps, based on the seller-specific commission_rate.
    #
    def house_commission
      price * seller.commission_rate
    end

    #
    # Compute the portion of the product's sale proceeds that
    # the seller keeps, net of Raise's commission.
    #
    def sellers_share
      price * (1 - seller.commission_rate)
    end

    #
    # The expectation would be Product.clear_all! would delete
    # only the Product records in the key-value store, but
    # actually, all items in the store would be deleted, because
    # Product inherits the Model.clear_all! method.
    #
    # Defining this to raise an error protects against the confusion.
    #
    def self.clear_all!
      raise "Use Model.clear_all!, no clear_all method scoped for Products only."
    end


    private

    #
    # Helper to validate the card value is larger than the price.
    #
    def verify_value_exceeds_price!
      if price >= value
        raise ArgumentError, "Card value (#{format_monetary_value(value)}) must be " +
                             "more than price (#{format_monetary_value(price)})"
      end
    end

    def verify_positive_price!
      if price <= 0
        validation_error!("price", "must be more than $0")
      end
    end

    def verify_positive_value!
      if value <= 0
        validation_error!("value", "must be more than $0")
      end
    end

    def verify_seller_exists!
      if Account.fetch(seller_name).nil?
        validation_error!("seller_name", "'#{seller_name}' not found")
      end
    end


  end
end
