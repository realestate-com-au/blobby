# frozen_string_literal: true

require "blobby/key_constraint"

module Blobby

  # A BLOB store backed by a Hash.
  #
  class InMemoryStore

    def self.from_uri(_uri)
      new
    end

    def initialize(hash = {})
      @hash = hash
    end

    def available?
      true
    end

    def [](key)
      KeyConstraint.must_allow!(key)
      StoredObject.new(@hash, key)
    end

    class StoredObject

      def initialize(hash, key)
        @hash = hash
        @key = key
      end

      attr_reader :key

      def exists?
        @hash.key?(key)
      end

      def read
        content = @hash[key]
        if block_given?
          yield content
          nil
        else
          content
        end
      end

      def write(content)
        content = if content.respond_to?(:read)
                    content.read
                  else
                    content.to_str.dup
                  end
        content = content.force_encoding("BINARY") if content.respond_to?(:force_encoding)
        @hash[key] = content
        nil
      end

      def delete
        !@hash.delete(key).nil?
      end

    end

  end

end
