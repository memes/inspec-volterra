# frozen_string_literal: true

module VolterraInspec
  # Array extends the stdlib Array to allow easier indexing within a universal matcher.
  # E.g. to access the 10th item in the array
  # describe volterra_thing(name: 'my_thing', ...) do
  #   its('list_property.9') { should cmp 'foobar' }
  # end
  class LookupArray < Array
    def self.create(data)
      data.each_with_object(new) do |v, memo|
        memo << v
      end
    end

    # def [](index)
    #   pp index
    #   slice(index)
    # end

    def respond_to_missing?(index, *_)
      pp index
      slice(index)
    end

    def method_missing(index, *_)
      pp index
      slice(index)
    end
  end

  # LookupHash extends the stdlib Hash to allow easier key-base lookup of values within a universal matcher.
  # E.g. to access the metadata label 'owner'
  # describe volterra_thing(name: 'my-thing', ...) do
  #   its('metadata.labels.owner') { should cmp 'me' }
  # end
  class LookupHash < Hash
    def self.create(data)
      data.each_with_object(new) do |(k, v), memo|
        memo[k.to_sym] = v
      end
    end

    def [](key)
      fetch(key.to_sym, nil)
    end

    def respond_to_missing?(key, *_)
      fetch(key.to_sym, nil)
    end

    def method_missing(key, *_)
      fetch(key.to_sym, nil)
    end
  end
end
