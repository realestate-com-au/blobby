# frozen_string_literal: true

module Blobby

  # A store decorator that logs writes and deletes
  #
  class LoggingStore

    def initialize(store, store_name, logger)
      @store = store
      @store_name = store_name
      @logger = logger
    end

    def available?
      store.available?
    end

    def [](key)
      StoredObject.new(
        store[key],
        :on_write => -> { logger.info(%(wrote to #{key.inspect} in #{store_name})) },
        :on_delete => -> { logger.info(%(deleted #{key.inspect} from #{store_name})) }
      )
    end

    private

    attr_reader :logger
    attr_reader :store
    attr_reader :store_name

    # Represents an object in the store.
    class StoredObject

      def initialize(object, callbacks = {})
        @object = object
        @on_write = callbacks[:on_write] || -> {}
        @on_delete = callbacks[:on_delete] || -> {}
      end

      def exists?
        @object.exists?
      end

      def read(&block)
        @object.read(&block)
      end

      def write(*args)
        @object.write(*args)
        @on_write.call
        nil
      end

      def delete
        deleted = @object.delete
        @on_delete.call if deleted
        deleted
      end

      private

      attr_reader :object
      attr_reader :on_write

    end

  end

end
