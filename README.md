# Coding Exercise: Giftcard Market

## Installation

I've packaged this up as a gem, following a structure I've used for standalone command-line Ruby projects in the past. It might seem a bit overkill for just a coding/screening exercise, but might as well take advantage of building on a known base, which gives structure and a few other things for free.

1. Clone the repo from the private BitBucket repo: `git clone https://github.com/polypressure/reservations.git`
1. `cd` into the `gcx` directory (short for "giftcard exchange", shorter than "giftcard_market").
1. Install the Ruby version, Ruby 2.2.2, which is specified in the `.ruby-version` file. I'm using RVM, so:
   `rvm install ruby-2.2.2`
1. Run `bin/setup` to install dependencies. These will be installed to the `gcx` gemset, which is specified in the `.ruby-gemset` file.
1. Run `rake test` to run the test suite. (This might take a while, as there is one test that reads a 10,000-line input file).
1. Run `rake install` to install the gem, including installing the executables.

## Usage

There are two executables:

* `bin/giftcard_market`:
  * This is the main executable, which takes input from STDIN.
  * Alternatively, you can give it a list of files on the command line, which it will process sequentially, treating them as a single file, concatenated file.
  * By default, the program process all input, skipping over any lines with error conditions. Errors are logged (with offending filename and line number) to STDERR.
  * If you give it the `-a` option, the program will abort immediately upon encountering bad input (e.g. an unknown command, missing or invalid arguments, missing accounts, etc.).
  * If you give it the `-p` option, the program will display a progress bar. This is mainly useful for large input sets. One caveat: the progress bar is displayed via STDERR, so if there are any errors, the progress bar gets pushed down (and if you're redirecting stderr to a file, the progress bar will show up there). Just re-run without the -p option if there are any errors.

* `bin/console`:
  * This starts up an IRB/Pry console with the giftcard_market/gcx code and dependencies loaded up.
  * Of course, always very handy to have an interactive console/REPL to experiment with and interact with code. Just remember to include the `GCX::` module prefix when referencing class names.

## Test suite

The test suite is also probably overkill for a screening/coding exercise, but oh well, you know…

Some other notes on the tests…

These days I generally avoid RSpec and stick with plain old Minitest (using plain old assertions, rather than the spec syntax). Just my personal preference, but I like that Minitest encourages simple, flat tests without a lot of noise. I like that it runs noticeably faster. And I like that the tests are just Ruby code, rather than a DSL with a bunch of magic—so writing custom assertions involves just extracting a method, not writing against a Matcher API.

Also, these days I also don't strictly adhere to the single-assertion-per-test rule. I find that by not cargo-culting that rule, tests often become easier to maintain, write, and read. However, I do try to stick with testing a single concept per test. Also, I'm generally not as mock-averse as many in the Minitest crowd are, and I strive to write isolated tests where practical. I do strongly prefer stubs over mocks though, and in general think of test doubles as a tool of last-resort.

Anyway, besides `rake test`, here are some other ways to run the tests:

```bash

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

### Auto-generating test input data

You can generate large input data files for testing using this rake task:

```bash

% rake 'generate_data[10000, input-data.txt]'

```

This creates a properly-formed test input file, using the (Faker)[https://github.com/stympy/faker] gem to generate fake name and brand data. The first parameter says how many `list_product` commands the file will contain. (The file will contain a random number of `add_account` commands that is larger than the number of listings, and a random number of `buy_product` commands that is less than the number of listings.) The second parameter is the filename where you want the generated data written.

Note that this tool is pretty crude—it won't generate any input lines with error conditions (e.g. bad commands, invalid prices, referential errors, etc). For now, it's mostly something to see how the program does with a bit more data.


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
  * Maybe a few too many responsibilities in one module, but as usual with parsing and validation, they're all closely-related and a pain to decouple.
  * The [Money](https://github.com/RubyMoney/money) and [Monetize](https://github.com/RubyMoney/monetize) gems are used for representing and processing money. Just easier than rolling my own with BigDecimal, etc.

### Key-value store and other notes:

* The [ModelStore](https://bitbucket.org/polypressure/gcx/src/3036dd6c43392e47ed5d7528ac468b3ad126140e/lib/gcx/model_store.rb?at=master) object is a wrapper for the [Moneta gem](https://github.com/minad/moneta). Out of the box, it's just using an in-memory, hash-based backend, but other backends (filesystem, relational/ORM, NoSQL, etc.) can be swapped in (mostly) transparently.
* Of course, much of the model-like functionality could have been pulled in from Rails, ActiveModel, or other similar gems, but I wanted to minimize the dependencies.
* In larger programs and Rails applications, I typically don't put any of the business logic in model objects, but in separate PORO domain objects. I also push parsing and validation to PORO form objects. YAGNI for this simple app.
