require 'test_helper'

#
# Base Model tests. Focuses on key-value store, coverage of
# validations, parsing, and formatting provided by subclass tests.

module GCX
  class ModelTest < Minitest::Test

    def setup
      reset_model_store!
    end


    test "Model#keys raises exception if not implemented" do
      model = StandInModelWithoutKey.new
      assert_raises_with_message(RuntimeError, /Must implement/) {
        model.keys
      }
    end


    #
    # Fetching and lookup...
    #

    test "the index operator (Model#[]) raises an exception when key not found" do
      assert_raises_with_message(ArgumentError, /not found/) {
        StandInModel["nothing"]
      }
    end

    test "Model#fetch returns nil when key not found" do
      assert_nil StandInModel.fetch("nothing")
    end

    test "the index operator (Model#[]) with fully-qualified key retrieves model" do
      assert_equal "Raise", Model["GCX::AccountRaise"].name
    end

    test "Model#fetch with fully-qualified key retrieves model" do
      assert_equal "Raise", Model.fetch("GCX::AccountRaise").name
    end

    test "subclass index operator (#[]) with unqualified key retrieves model" do
      assert_equal "Raise", Account["Raise"].name
    end

    test "subclass fetch with unqualified key retrieves model" do
      assert_equal "Raise", Account.fetch("Raise").name
    end

    test "subclass index operator (#[]) with composite key retrieves model" do
      model = StandInModelWithCompositeKey.new("bar", "123")
      model.store

      assert_equal model, StandInModelWithCompositeKey["bar", "123"]
    end

    test "subclass fetch with composite key retrieves model" do
      model = StandInModelWithCompositeKey.new("bar", "123")
      model.store

      assert_equal model, StandInModelWithCompositeKey.fetch("bar", "123")
    end


    #
    # Saving...
    #

    test "Model#store saves new model" do
      model = StandInModel.new("foo")

      model.store

      assert_equal model, StandInModel["foo"]
    end

    test "Model#store updates existing model" do
      model = Account["Raise"]
      model.balance = 1000

      model.store

      assert_equal 1000, Account["Raise"].balance
    end


    #
    # Deletion...
    #

    test "Model#delete! deletes model" do
      StandInModel.new("foo").store
      model = StandInModel["foo"]

      model.delete!

      assert_nil StandInModel.fetch("foo")
    end

    test "Model.clear_all! clears all models from the store" do
      StandInModel.new("foo").store
      StandInModelWithCompositeKey.new("bar", "123").store
      StandInModel.new("baz").store
      StandInModelWithCompositeKey.new("qux", "45678").store
      StandInModelWithCompositeKey.new("quux", "123").store
      StandInModel.new("quux").store
      assert_equal 7, Model.all_keys.count

      Model.clear_all!

      assert_equal 0, Model.all_keys.count
    end


    #
    # Fetching all keys...
    #

    test "Model.all_keys returns all keys for all model types" do
      StandInModel.new("foo").store
      StandInModelWithCompositeKey.new("bar", "123").store
      StandInModel.new("baz").store
      StandInModelWithCompositeKey.new("qux", "45678").store
      StandInModelWithCompositeKey.new("quux", "123").store
      StandInModel.new("quux").store

      assert_equal [ "GCX::AccountRaise",
                     "GCX::StandInModelfoo",
                     "GCX::StandInModelWithCompositeKeybar:123",
                     "GCX::StandInModelbaz",
                     "GCX::StandInModelWithCompositeKeyqux:45678",
                     "GCX::StandInModelWithCompositeKeyquux:123",
                     "GCX::StandInModelquux"], Model.all_keys
    end

    test "Model#demodulized_name strips out modules from fully-qualified class name" do
      assert_equal "StandInModel", GCX::StandInModel.demodulized_name
      assert_equal "ModelNotInModule", ModelNotInModule.demodulized_name
      assert_equal "ModelInDeeplyNestedModules", GCX::Foo::Bar::Baz::ModelInDeeplyNestedModules.demodulized_name
    end


    #
    # Comparison and equality...
    #

    test "Model instances with the same class and values are equal" do
      model = StandInModelWithCompositeKey.new("bar", "123")
      StandInModelWithCompositeKey.new("bar", "123").store

      assert_equal model, StandInModelWithCompositeKey["bar", "123"]
    end

    test "Model instances with the different classes are not equal" do
      model = StandInModel.new("bar")
      StandInModelWithCompositeKey.new("bar", "123").store

      refute_equal model, StandInModelWithCompositeKey["bar", "123"]
    end

    test "Model instances with the same values but different classes are not equal" do
      model = StandInModelWithCompositeKey2.new("bar", "123")
      StandInModelWithCompositeKey.new("bar", "123").store

      refute_equal model, StandInModelWithCompositeKey["bar", "123"]
    end
  end

end

class GCX::StandInModelWithoutKey < GCX::Model

end

class GCX::StandInModel < GCX::Model
  attr_accessor :a_field

  def initialize(a_field_value)
    self.a_field = a_field_value
  end

  def keys
    [ a_field ]
  end
end

class GCX::StandInModelWithCompositeKey < GCX::Model
  attr_accessor :field1, :field2

  def initialize(field1, field2)
    self.field1 = field1
    self.field2 = field2
  end

  def keys
    [ field1, field2 ]
  end
end

class GCX::StandInModelWithCompositeKey2 < GCX::Model
  attr_accessor :field1, :field2

  def initialize(field1, field2)
    self.field1 = field1
    self.field2 = field2
  end

  def keys
    [ field1, field2 ]
  end
end


class ModelNotInModule < GCX::Model; end

module GCX
  module Foo
    module Bar
      module Baz
        class ModelInDeeplyNestedModules < GCX::Model; end
      end
    end
  end
end
