require "blobby/filesystem_store"
require "blobby/in_memory_store"
require "blobby/version"

module Blobby

  def self.store(path)
    case path
    when %r(file://(/.*))
      FilesystemStore.new($1)
    when 'mem:'
      InMemoryStore.new($1)
    else
      FilesystemStore.new(path)
    end
  end

end
