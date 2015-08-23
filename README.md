# Coding Exercise: Giftcard Market

## Installation

I've packaged this up as a gem, following a structure I've used for standalone command-line Ruby projects in the past. It might seem a bit overkill for just a coding/screening exercise, but might as well take advantage of building on a known base.

1. Clone the repo from the private BitBucket repo: `git clone https://github.com/polypressure/reservations.git`
1. `cd` into the `gcx` directory (short for "giftcard exchange").
1. Install the Ruby version, Ruby 2.2.2, which is specified in the `.ruby-version` file. I'm using RVM, so:
   `rvm install ruby-2.2.2`
1. Run `bin/setup` to install dependencies. These will be installed to the `gcx` gemset, which is specified in the `.ruby-gemset` file.
1. Run `rake test` to run the test suite.
1. Run `rake install` to install the gem, including installing the executables.

## Usage

There are two executables:

* `bin/giftcard_market`:
  * This is the main executable, which takes input from STDIN.
  * Alternatively, you can give it a list of files on the command line, which it will process sequentially, treating them as a single file.
  * By default, the program process all input, skipping over any lines with error conditions. Errors are logged (with offending filename and line number) to STDERR.
  * If you provide the `-a` option, the program will abort immediately upon encountering bad input (e.g. an unknown command, missing or invalid arguments, missing accounts, etc.).

* `bin/console`:
  * This starts up an IRB/Pry console with the giftcard_market/gcx code and dependencies loaded up.
  * Of course, always very handy to have a Rails-like console. Just remember to include the `GCX::` module prefix when referencing class names.

## Test suite

The test suite is also probably overkill for a screening/coding exercise, but it's not just about verifying the correctness of the code, but the completeness of your thinking.

Some other notes on the tests…

These days I generally avoid RSpec and stick with plain old Minitest (using plain old assertions, rather than the spec syntax). Just my personal preference, but I like that Minitest encourages simple, flat tests without a lot of noise. I like that it runs noticeably faster. And I like that the tests are just Ruby code, rather than a DSL with a bunch of magic. Writing custom assertions involves just extracting a method, not writing against a Matcher API.

Also, these days I also don't necessarily strictly adhere to the single-assertion-per-test rule. I find that by not cargo-culting that rule, tests often become easier to maintain, write, and read. However, I do try to stick with testing a single concept per test. Also, I'm generally not as mock-averse as many in the Minitest crowd are, and I strive to write isolated tests where practical. I do strongly prefer stubs over mocks, and in general think of test doubles as a tool of last-resort.

Besides `rake test`, some other ways to run the tests:

```ruby

# Run the whole suite as usual with rake:
% rake test

# View the simplecov coverage report generated after running rake test:
% open coverage/index.html

# Run just the account test:
% m test/models/account_test.rb

# Run just the single test on a specific line of a test file:
% m test/command_test.rb:53

# Run just the model tests:
% m test/models

```


## Design Notes

It's a fairly conventional, pedestrian OOP design:

### Entry point, file and command parsing:
* The [`giftcard_market`](https://bitbucket.org/polypressure/gcx/src/3036dd6c43392e47ed5d7528ac468b3ad126140e/bin/giftcard_market?at=master) executable loads all the required libraries via [`lib/gcx.rb`](https://bitbucket.org/polypressure/gcx/src/3036dd6c43392e47ed5d7528ac468b3ad126140e/lib/gcx.rb?at=master), then kicks off processing with the [`Application#run`](https://bitbucket.org/polypressure/gcx/src/3036dd6c43392e47ed5d7528ac468b3ad126140e/bin/giftcard_market?at=master#giftcard_market-6) method.
* The [`Application`](https://bitbucket.org/polypressure/gcx/src/3036dd6c43392e47ed5d7528ac468b3ad126140e/lib/gcx/application.rb?at=master) object parses any command-line arguments and options, reads the input, and hands off the individual lines to [`Command`](https://bitbucket.org/polypressure/gcx/src/3036dd6c43392e47ed5d7528ac468b3ad126140e/lib/gcx/command.rb?at=master) objects.
* The [`Command`](https://bitbucket.org/polypressure/gcx/src/3036dd6c43392e47ed5d7528ac468b3ad126140e/lib/gcx/command.rb?at=master) parses the line and dispatches/delegates the processing the commands to two "model" objects (scare quotes because these aren't Rails ActiveRecord objects).


### Model objects and main business logic:
* The model objects are defined in [`lib/gcx/models`](https://bitbucket.org/polypressure/gcx/src/3036dd6c43392e47ed5d7528ac468b3ad126140e/lib/gcx/models/?at=master), and are subclasses of a base [`Model`](https://bitbucket.org/polypressure/gcx/src/3036dd6c43392e47ed5d7528ac468b3ad126140e/lib/gcx/models/model.rb?at=master) object which provides input parsing, validation, and formatting, as well as methods to store/fetch/delete models to an in-memory, hash-based key-value store.
* There are two model objects:
  * [`Account`](https://bitbucket.org/polypressure/gcx/src/3036dd6c43392e47ed5d7528ac468b3ad126140e/lib/gcx/models/account.rb?at=master) contains the attributes and logic you'd pretty much expect, with the key methods letting you:
    * Add a new account to the marketplace.
    * Credit and debit amounts to/from the account's balance.
    * Generate the Account Summary report.
  * [`Product`](https://bitbucket.org/polypressure/gcx/src/3036dd6c43392e47ed5d7528ac468b3ad126140e/lib/gcx/models/product.rb?at=master) also is mostly unsurprising, with the key methods letting you:
    * List a product on the marketplace.
    * Purchase the product—including making all related credits and deductions (for sale proceeds, commissions, and purchase price), and removing the product from the marketplace.
* Parsing, validation, and formatting logic is defined in the [`GCX::Validations`](https://bitbucket.org/polypressure/gcx/src/3036dd6c43392e47ed5d7528ac468b3ad126140e/lib/gcx/models/validations.rb?at=master) mixin:
  * Maybe a bit too many responsibilities in one module, but as usual with parsing and validation, they're all closely-related and fairly coupled.
  * The [Money](https://github.com/RubyMoney/money) and [Monetize](https://github.com/RubyMoney/monetize) gems are used for representing and processing money. Just easier than rolling my own with BigDecimal, etc.

### Key-value store and other notes:

* The [ModelStore](https://bitbucket.org/polypressure/gcx/src/3036dd6c43392e47ed5d7528ac468b3ad126140e/lib/gcx/model_store.rb?at=master) object is a wrapper for the [Moneta gem](https://github.com/minad/moneta). Out of the box, it's just using an in-memory, hash-based backend, but other backends (filesystem, relational/ORM, NoSQL, etc.) can be swapped in (mostly) transparently.
* Of course, much of the model-like functionality could have been pulled in from Rails, ActiveModel, or other similar gems, but I wanted to minimize the dependencies.
* In larger programs and Rails applications, I typically don't put any of the business logic in model objects, but in separate PORO domain objects. I also push parsing and validation to PORO form objects. YAGNI for this simple app.
