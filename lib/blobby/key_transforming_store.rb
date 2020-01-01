# frozen_string_literal: true

require "blobby/key_constraint"
require "fileutils"
require "forwardable"
require "pathname"
require "tempfile"

module Blobby

  # A BLOB store that decorates another store and allows key transformation
  #
  class KeyTransformingStore < SimpleDelegator

    def initialize(store, &key_transformation_strategy)
      super(store)
      @key_transformation_strategy = key_transformation_strategy
    end

    def [](key)
      transformed_key = @key_transformation_strategy.call(key)
      __getobj__[transformed_key]
    end

  end

end
