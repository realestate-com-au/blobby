require "spec_helper"

require "blobby/filesystem_store"
require "blobby/key_transforming_store"
require "blobby/store_behaviour"
require "tmpdir"

describe Blobby::KeyTransformingStore do

  let(:memory) { Hash.new }

  subject do
    described_class.new(Blobby::InMemoryStore.new(memory)) { |key| key }
  end

  it_behaves_like Blobby::Store

  let(:content) { "CONTENT" }

  context "with a noop key transforming strategy" do

    describe "#write" do

      let(:key) { "NAMESPACED/KEY" }
      let(:transformed_key) { key }

      before do
        subject[key].write(content)
      end

      it "uses the transformed key" do
        expect(subject[key]).to exist
        expect(memory.key?(transformed_key)).to be_truthy
      end

      it "has the correct contents" do
        expect(subject[key].read).to eq(content)
        expect(memory[transformed_key]).to eq(content)
      end
    end

  end

  context "with a sharding key transformation strategy" do

    subject do
      described_class.new(Blobby::InMemoryStore.new(memory)) do |key|
        [key[0, 2], key[2, 2], key[4, 2], key].join "/"
      end
    end

    describe "#write" do

      let(:key) { "aabbccdd.png" }
      let(:transformed_key) { "aa/bb/cc/aabbccdd.png" }

      before do
        subject[key].write(content)
      end

      it "uses the transformed key" do
        expect(subject[key]).to exist
        expect(memory.key?(transformed_key)).to be_truthy
      end

      it "has the correct contents" do
        expect(subject[key].read).to eq(content)
        expect(memory[transformed_key]).to eq(content)
      end
    end

  end

  context "with a shard ignoring key transformation strategy" do

    subject do
      described_class.new(Blobby::InMemoryStore.new(memory)) do |key|
        key.split("/").last
      end
    end

    describe "#write" do

      let(:key) { "/aa/bb/cc/aabbccdd.png" }
      let(:transformed_key) { "aabbccdd.png" }

      before do
        subject[key].write(content)
      end

      it "uses the transformed key" do
        expect(subject[key]).to exist
        expect(memory.key?(transformed_key)).to be_truthy
      end

      it "has the correct contents" do
        expect(subject[key].read).to eq(content)
        expect(memory[transformed_key]).to eq(content)
      end
    end

  end

end
