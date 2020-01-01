# frozen_string_literal: true

require "blobby/key_constraint"

module Blobby

  # A BLOB store that is always successful.
  #
  class FakeSuccessStore

    def available?
      true
    end

    def [](key)
      KeyConstraint.must_allow!(key)
      StoredObject.new
    end

    # Handle to an object in the store.
    class StoredObject

      def exists?
        true
      end

      def read
        image_path = Pathname(File.dirname(__FILE__)) + "placeholder.png"
        image_path.open("rb") do |io|
          if block_given?
            while (chunk = io.read(512))
              yield chunk
            end
            nil
          else
            io.read
          end
        end
      rescue Errno::ENOENT
        nil
      end

      def write(_content)
        nil
      end

      def delete
        true
      end

    end

  end

end
