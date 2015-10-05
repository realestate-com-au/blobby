require "blobby/filesystem_store"
require "blobby/http_store"
require "blobby/in_memory_store"
require "blobby/version"
require "uri"

# BLOB storage
#
module Blobby

  class << self

    def store(uri)
      uri = URI(uri)
      factory = store_factories[uri.scheme]
      fail ArgumentError, "unknown store type: #{uri}" if factory.nil?
      factory.from_uri(uri)
    end

    def register_store_factory(uri_scheme, factory)
      store_factories[uri_scheme] = factory
    end

    private

    def store_factories
      @store_factories ||= {}
    end

  end

  register_store_factory nil, FilesystemStore
  register_store_factory "file", FilesystemStore
  register_store_factory "http", HttpStore
  register_store_factory "https", HttpStore
  register_store_factory "in-memory", InMemoryStore

end
