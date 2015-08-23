require 'gcx'
require 'faker'
require 'ruby-progressbar'

# The dataset generator was initially dog slow, a quick profiling run
# showed that the bottleneck was Model#all_keys. Caching the list of
# account names and product keys fixed the problem.
#
# require 'ruby-prof'


#
# Crude tool to generate larger input data sets for testing.
# For now, doesn't generate any lines with errors.
#
module GCX
  class DatasetGenerator

    def self.generate_input_file(num_listings=1000, filename="generated.txt")
      num_listings = num_listings.to_i
      pbar = ProgressBar.create(total: num_listings, format: "%t: %p%%|%B")

      File.open(filename, 'w') do |file|
        g = DatasetGenerator.new

        # Seed initial accounts, need at least two first.
        writeln(file, g.add_account_command)
        writeln(file, g.add_account_command)

        num_listings.to_i.times do
          writeln(file, g.add_account_command) if rand < 0.7
          writeln(file, g.list_product_command)
          writeln(file, g.add_account_command) if rand < 0.5
          writeln(file, g.buy_product_command) if rand < 0.5

          pbar.increment
        end
      end

    end

    def self.writeln(file, string)
      file.write("#{string}\n")
    end

    def initialize
      @account_names = []
      @product_keys = []
    end

    def add_account_command
      name = account_name
      cmd = "add_account #{name} #{commission_rate}".strip
      Command.process(cmd)
      @account_names << name
      cmd
    end

    def list_product_command
      product_key = [ brand, card_id ]
      cmd = "list_product #{seller_name} \"#{product_key[0]}\" #{product_key[1]} #{value_and_price}"
      Command.process(cmd)
      @product_keys << product_key
      cmd
    end

    def buy_product_command
      product = listed_product
      cmd = "buy_product #{buyer_name(product.seller_name)} \"#{product.brand}\" #{product.card_id}"
      Command.process(cmd)
      @product_keys.delete([product.brand, product.card_id])
      cmd
    end

    def account_name
      Faker::Name.first_name.gsub(/'/, '')
    end

    def commission_rate
      (rand > 0.2 ? '' : ((rand(11) + 10)/100.0).to_s[0..3])
    end

    def seller_name
      existing_account_name
    end

    def brand
      Faker::Company.name.gsub(/'/, '')
    end

    def card_id
      Faker::Number.number(10)
    end

    def value_and_price
      value = Monetize.parse(rand(50000)/100+10)
      price = Monetize.parse(value * (rand * 0.14 + 0.85))
      "#{value.format(sign_before_symbol: true)} #{price.format(sign_before_symbol: true)}"
    end

    def buyer_name(exclude)
      name = existing_account_name
      until name != exclude
        name = existing_account_name
      end
      name
    end

    def existing_account_name
      @account_names[rand(@account_names.count)]
    end

    def listed_product
      Product[@product_keys[rand(@product_keys.count)]]
    end

  end
end
