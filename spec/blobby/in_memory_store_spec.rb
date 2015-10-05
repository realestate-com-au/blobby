require "spec_helper"

require "blobby/in_memory_store"
require "blobby/store_behaviour"

describe Blobby::InMemoryStore do

  subject do
    described_class.new
  end

  it_behaves_like Blobby::Store

end
