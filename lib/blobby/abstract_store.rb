# frozen_string_literal: true

require "blobby/key_constraint"

module Blobby

  # A store of BLOBs.
  # @abstract
  class AbstractStore

    # @return true if the store is available for use
    def available?
      true
    end

    # Access an object in the store.
    # @param key [String] object address
    # @return [StoredObject] a handle to the addressed object
    def [](key)
      KeyConstraint.must_allow!(key)
      StoredObject.new
    end

    # A handle to an object in the BLOB-store.
    # @abstract
    class StoredObject

      # Check for existence.
      # @return true if the object exists
      def exists?
        false
      end

      # @overload read
      #   Read BLOB data.
      #   @return [String] data if the object exists
      #   @return [nil] if the object doesn't exist
      # @overload read
      #   Stream BLOB data in chunks.
      #   @yield [chunk] each chunk of data
      #   @return [void]
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
