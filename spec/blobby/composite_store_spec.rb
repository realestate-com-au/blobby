# frozen_string_literal: true

require "spec_helper"

require "blobby/composite_store"
require "blobby/in_memory_store"
require "blobby/store_behaviour"

describe Blobby::CompositeStore do

  let(:storeA) { Blobby::InMemoryStore.new }
  let(:storeB) { Blobby::InMemoryStore.new }
  let(:stores) { [storeA, storeB] }

  subject do
    described_class.new(stores)
  end

  it_behaves_like Blobby::Store

  let(:key) { "KEY" }
  let(:content) { "CONTENT" }

  describe "#write" do

    before do
      subject[key].write(content)
    end

    it "writes to all stores" do
      stores.all? do |store|
        expect(store[key].read).to eq(content)
      end
    end

  end

  context "for a key that only exists in the second store" do

    before do
      storeB[key].write(content)
    end

    describe "#exists?" do
      it "is true" do
        expect(subject[key]).to exist
      end
    end

    describe "#read" do
      it "returns the content" do
        expect(subject[key].read).to eq(content)
      end
    end

  end

end
