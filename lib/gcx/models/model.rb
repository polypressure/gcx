#
# Base class representing a record in the marketplace, e.g.
# an Account or Reservation.
#
# Provides methods for validation, parsing and formatting monetary
# values, etc.
#
# Also provides methods to store, fetch, and delete itself from the
# key-value store, which is an in-memory store by default, but which
# can be changed transparently to use different backends (filesystem,
# relational/ORM, NoSQL, etc.) as specified by the Moneta gem.
# See https://github.com/minad/moneta
#
module GCX
  class Model
    include Validations

    class << self; attr_reader :model_store end
    @model_store = ModelStore.new

    #
    # Lookup key for object, subclasses must implement...
    #
    def keys
      raise "Must implement #{self.class.name}#keys method to return lookup key"
    end

    #
    # Retrive the model object from the key-value store using
    # the given keys.
    #
    # Raises an error if model not found.
    #
    def self.[](*keys)
      Model.model_store.fetch(self, keys).tap do |model|
        raise ArgumentError, "#{self.demodulized_name} not found with key: #{keys}" if !model
      end
    end

    #
    # Retrive the model object from the key-value store using
    # the given keys.
    #
    # Returns nil if model not found.
    #
    def self.fetch(*keys)
      Model.model_store.fetch(self, keys)
    end

    #
    # Save a new model to the key-value store, or update it
    # if already in the store.
    #
    def store
      Model.model_store.store(self)
    end

    #
    # Delete the model from the key-value store.
    #
    def delete!
      Model.model_store.delete!(self)
    end

    #
    # List all keys in the key-value store, scoped for the model type,
    # e.g. Account.all_keys returns all the keys just for Accounts.
    #
    def self.all_keys
      prefix = (self == Model) ? '' : self.name

      Model.model_store.all_keys.map { |key|
        key.match(/^#{prefix}(.+)/) { |m| m[1] }
      }.compact
    end

    #
    # Clear all models from the key-value store.
    #
    def self.clear_all!
      Model.model_store.clear_all!
    end

    #
    # Helper method to return the class name, removing any
    # module names.
    #
    def self.demodulized_name
      name.match(/(.*::)?(.+)$/)[2]
    end

    def ==(other)
      return false unless self.class == other.class

      instance_variables.each do |ivar|
        name = ivar[1..-1]
        if respond_to? "#{name}="
          return false if instance_variable_get(ivar) != other.instance_variable_get(ivar)
        end
      end
    end
  end
end
