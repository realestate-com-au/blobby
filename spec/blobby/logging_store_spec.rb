require "spec_helper"

require "blobby/in_memory_store"
require "blobby/logging_store"
require "blobby/store_behaviour"
require "logger"
require "stringio"

describe Blobby::LoggingStore do

  let(:backing_store) { Blobby::InMemoryStore.new }
  let(:log_buffer) { StringIO.new }
  let(:logger) { Logger.new(log_buffer) }
  let(:log_output) { log_buffer.string }

  subject do
    described_class.new(backing_store, "THE STORE", logger)
  end

  it_behaves_like Blobby::Store

  describe "#write" do

    before do
      subject["foo"].write("bar")
    end

    it "logs the write" do
      expect(log_output).to include(%(wrote to "foo" in THE STORE))
    end

  end

  describe "#delete" do

    before do
      subject["foo"].write("bar")
      subject["foo"].delete
    end

    it "logs the delete" do
      expect(log_output).to include(%(deleted "foo" from THE STORE))
    end

  end

end
