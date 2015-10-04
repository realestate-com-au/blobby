require "blobby/filesystem_store"
require "blobby/http_store"
require "blobby/in_memory_store"
require "blobby/version"
require "uri"

module Blobby

  def self.store(uri)
    uri = URI(uri)
    case uri.scheme
    when "file", nil
      FilesystemStore.new(uri.path)
    when "http", "https"
      HttpStore.new(uri)
    when "mem"
      InMemoryStore.new
    else
      raise ArgumentError, "unknown store URI: #{uri}"
    end
  end

end
