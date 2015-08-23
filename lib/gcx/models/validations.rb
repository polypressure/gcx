#
# Helper methods to parse, validate, and format model fields.
#
module GCX
  module Validations
    #
    # For now, don't bother with i18n, locale files, and money formatting.
    #
    Money.use_i18n = false

    #
    # Raise a validation error for the specified field name, with
    # the given error message.
    #
    def validation_error!(field_name, message)
      raise ArgumentError, "Validation error: #{field_name} #{message}."
    end

    #
    # Set the specified field to the given value, validating
    # that it isn't blank.
    #
    def set_required_field(field_name, field_value)
      validation_error!(field_name, "is required") if blank?(field_value)
      set_field(field_name, field_value.strip.squeeze(' '))
    end

    #
    # Set the specified field to the given value, validating
    # that it's a valid dollar value, and parsing it into
    # Money object, see https://github.com/RubyMoney/money.
    #
    def set_monetary_field(field_name, field_value)
      unless valid_monetary_value?(field_value)
        validation_error!(field_name,
                          "must be a valid dollar value (dollar sign and " +
                          "cents are mandatory, minus sign if any preceds " +
                          "dollar sign, commas optional)")
      end
      set_field(field_name, parse_monetary_value(field_value))
    end

    #
    # Set the specified field to the given value, validating
    # that it's a 10-digit ID.s
    #
    def set_card_id_field(field_name, field_value)
      unless valid_card_id?(field_value)
        validation_error!(field_name, "must be a 10-digit card ID")
      end
      set_field(field_name, field_value)
    end

    #
    # Set the specified field to the given value, validating
    # that it's a valid percentage value, and parsing it into
    # a BigDecimal. Messy because BigDecimal parses invalid
    # numeric strings as zero, and because we have to do a second
    # numerical range check after validating the string.
    #
    def set_percentage_field(field_name, field_value)
      unless valid_percentage?(field_value)
        validation_error!(field_name,
                          "must be a percentage expressed as a zero-padded " +
                          "decimal to two decimal places (e.g. 0.17)")
      end

      as_big_decimal = BigDecimal.new(field_value)
      if (as_big_decimal >= 0 && as_big_decimal <= 1)
        set_field(field_name, as_big_decimal)
      else
        validation_error!(field_name, "must be between 0 and 1 inclusive")
      end
    end

    #
    # Format the given Money object with a dollar sign and two
    # decimal places, with a minus sign preceding the dollar sign
    # for negative values.
    #
    def format_monetary_value(money)
      money.format(sign_before_symbol: true)
    end


    #
    # Various validation, parsing, and formatting helper methods...
    #

    def blank?(value)
      value.nil? || value.empty?
    end

    #
    # 10-digit numeric string, e.g. "1234567890"
    #
    def valid_card_id?(card_id)
      !!(/^\d{10}$/ =~ card_id)
    end

    #
    # Non-negative fractional amount, leading 0 or 1, decimal point required,
    # two digits after decimal point max.
    #
    # e.g. "0.15", "1.00", "0.11"
    #
    def valid_percentage?(value)
      !!(/^[0,1](\.\d{1,2})?$/ =~ value)
    end

    #
    # Leading dollar-sign, must include cents, optionally includes
    # comma-separators, negative values have a minus sign preceeding
    # the dollar sign,
    #
    # e.g. "$10.00", "-$50.00", "$10000.00", "$2,500.25"
    #
    def valid_monetary_value?(value)
      !!(/^[+-]?\$[0-9]{1,3}(?:,?[0-9]{3})*\.[0-9]{2}$/ =~ value)
    end

    #
    # Parse monetary string using Monetize gem.
    #
    def parse_monetary_value(value)
      Monetize.parse(value)
    end

    #
    # Helper method to set an attribute given its name as a string
    # or symbol and the new value.
    #
    def set_field(field_name, field_value)
      send("#{field_name}=", field_value)
    end

  end

end
