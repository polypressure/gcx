#
# Wrapper for key-value store.
#
# Out-of-the-box, this just uses an in-memory backend (a hash),
# but alternate backends can be configured (filesystem,
# relational/ORM, NoSQL, etc.) as specified by the Moneta gem.
# See https://github.com/minad/moneta
#
# Setting a new key-value store should mostly be transparent,
# however, you will likely need to patch the backend adapter
# to provide a method that returns all keys in the store. See
# the bottom of this file for how the in-memory backend
# is patched.
#
module GCX
  class ModelStore

    def initialize
      @kvstore = ::Moneta.new(:Memory)
    end

    def fetch(klass, *keys)
      substore_for(klass)[composite_key(keys)]
    end

    def store(model)
      substore_for(model.class)[composite_key(model.keys)] = model
    end

    def delete!(model)
      substore_for(model.class).delete(composite_key(model.keys))
    end

    def all_keys
      @kvstore.all_keys
    end

    def clear_all!
      @kvstore.clear
    end


    private

    def substore_for(klass)
      klass == Model ? @kvstore : @kvstore.prefix(klass.name)
    end

    def composite_key(keys)
      keys.join(':')
    end

  end

end

#
# Patch the Moneta Memory adapter to provide a method
# that returns all the keys in the store.
#
# Kind of messes up the dream that we can transparently
# swap backend implementation for the backend-store.
#
module Moneta
  class Proxy
    def all_keys
      adapter.all_keys
    end
  end

  module HashAdapter
    # Expand on https://github.com/minad/moneta/blob/master/lib/moneta/mixins.rb
    def all_keys
      @backend.keys
    end
  end
end
