require "uri"

module Blobby

  # Defines the keys we allow for use in BLOB-store implementations.
  #
  # Basically, we allow anything that would be a valid URI "path" component.
  #
  module KeyConstraint

    extend self

    BAD_PATTERNS = [
      %r{\A\Z}, # blank
      %r{\A/}, # leading slash
      %r{/\Z}, # trailing slash
      %r{//+}, # multiple slashes
      %r{:} # colon
    ].freeze

    def allows?(key)
      BAD_PATTERNS.none? { |pattern| pattern =~ key } &&
        URI.parse(key).path == key
    rescue URI::InvalidURIError
      false
    end

    def must_allow!(key)
      fail ArgumentError, "invalid key: #{key.inspect}" unless allows?(key)
    end

  end

end
