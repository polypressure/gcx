#
# Represents an account in the marketplace, with name,
# Raise commission_rate, and current balance attributes.
#
# Provides methods to credit/debit the account's balance.
#
module GCX
  class Account < Model

    attr_accessor :name, :commission_rate, :balance

    #
    # Initialize a new Account.
    #
    # Raises an error if:
    #  - name is blank
    #  - commission_rate is not a valid percentage
    #  - balance is not a valid dollar value
    #
    def initialize(name:, commission_rate:, balance: "$0.00")
      set_required_field(:name, name)
      set_percentage_field(:commission_rate, commission_rate)
      set_monetary_field(:balance, balance)
    end

    #
    # An Account's lookup key consists only of the name.
    #
    def keys
      [ name ]
    end

    #
    # Add a new account given the name and commission_rate,
    # which defaults to 0.15.
    #
    # Raises validation errors as described in #initialize.
    #
    # If account already exists with given key, doesn't overwrite.
    #
    def self.add(name, commission_rate="0.15")
      account = Account.fetch(name)
      unless account
        account = new(name: name, commission_rate: commission_rate)
        account.store
      end
    end

    #
    # The house "Raise" account.
    #
    def self.house_account
      Account["Raise"]
    end

    #
    # Add the given amount to the account's balance and
    # re-save the account to the key-value store.
    #
    def credit!(amount)
      self.balance += parse_monetary_value(amount)
      self.store
    end

    #
    # Subtract the given amount to the account's balance
    # and re-save the account to the key-value store.
    #
    def debit!(amount)
      self.balance -= parse_monetary_value(amount)
      self.store
    end

    #
    # Return the formatted account balance, e.g.
    #   "$25.00" or "-$80.00"
    #
    def formatted_balance
      format_monetary_value(balance)
    end

    #
    # Return a summary of all the accounts and their balances
    # as an array, sorted in alpha order, with the house
    # Raise account at the end.
    #
    def self.summary
      summary = non_house_keys.sort.map do |key|
        account = Account[key]
        "#{account.name} #{account.formatted_balance}"
      end

      house = Account.house_account
      summary << "#{house.name} #{house.formatted_balance}"
    end

    #
    # The expectation would be Account.clear_all! would delete
    # only the Account records in the key-value store, but
    # actually, all items in the store would be deleted, because
    # Account inherits the Model.clear_all! method.
    #
    # Defining this to raise an error protects against the confusion.
    #
    def self.clear_all!
      raise "Use Model.clear_all!, no clear_all method scoped for Accounts only."
    end


    private

    def self.non_house_keys
      Account.all_keys.reject { |key| key == "Raise"  }
    end

    #
    # Create the house Raise account.
    #
    def self.create_house_account
      Account.add("Raise") unless Account.fetch("Raise")
    end

    create_house_account
  end
end
