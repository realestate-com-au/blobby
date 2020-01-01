# frozen_string_literal: true

module Blobby

  # Compose a number of stores.
  #
  # Writes go to all stores. Reads use the first store to respond.
  #
  class CompositeStore

    def initialize(stores)
      @stores = stores
    end

    def [](key)
      KeyConstraint.must_allow!(key)
      objects = stores.map { |store| store[key] }
      StoredObject.new(objects)
    end

    def available?
      stores.all?(&:available?)
    end

    private

    attr_reader :stores

    class StoredObject

      def initialize(objects)
        @objects = objects
      end

      def exists?
        objects.any?(&:exists?)
      end

      def read(&block)
        objects.each do |o|
          return o.read(&block) if o.exists?
        end
        nil
      end

      def write(content)
        content = content.read if content.respond_to?(:read)
        objects.each do |o|
          o.write(content)
        end
        nil
      end

      def delete
        objects.all?(&:delete)
      end

      private

      attr_reader :objects

    end

  end

end
