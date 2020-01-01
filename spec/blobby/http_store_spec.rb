# frozen_string_literal: true

require "spec_helper"

require "ostruct"
require "blobby/http_store"
require "blobby/in_memory_store"
require "blobby/store_behaviour"
require "sinatra/base"
require "sham_rack"

describe Blobby::HttpStore do

  let(:backing_store) do
    {}
  end

  class FakeStorageService < Sinatra::Base

    set :show_exceptions, false

    put %r{/(.+)} do
      halt 413 if request.content_type == "application/x-www-form-urlencoded"
      status 201 unless store.key?(key)
      store[key] = OpenStruct.new(:content_type => request.content_type, :body => request.body.read)
      nil
    end

    get %r{/(.+)} do
      halt 404 unless store.key?(key)
      halt 200 if request.head?
      content_type "application/octet-stream"
      store[key].body
    end

    delete %r{/(.+)} do
      halt 404 unless store.key?(key)
      store.delete(key)
      nil
    end

    def store
      settings.backing_store
    end

    def key
      params[:captures].first.tap do |key|
        fail "hell" if key =~ /FAIL/ # simulate failure
      end
    end

  end

  let(:fake_storage_service) do
    subclass = Class.new(FakeStorageService)
    subclass.set :backing_store, backing_store
    subclass
  end

  let(:http_storage_host) { "storeit.com" }

  before do
    ShamRack.at(http_storage_host).mount(fake_storage_service)
  end

  after do
    ShamRack.unmount_all
  end

  subject do
    described_class.new("http://#{http_storage_host}/object-prefix/")
  end

  before do
    allow(subject).to receive(:retry_intervals).and_return([0.01, 0.02])
  end

  it_behaves_like Blobby::Store

  describe "#write" do

    let(:content) { "CONTENT" }

    before do
      subject["foobar"].write(content)
    end

    it "PUTs stuff in the remote store" do
      expect(backing_store["object-prefix/foobar"].body).to eq(content)
    end

    it "presents it as binary data" do
      expect(backing_store["object-prefix/foobar"].content_type).to eq("application/octet-stream")
    end

  end

  context "when a server error occurs" do

    let(:key) { "SERVER/FAIL" }

    describe "#read" do

      it "raises an exception" do
        expect do
          subject[key].read
        end.to raise_error("hell")
      end

    end

    describe "#write" do

      it "raises an exception" do
        expect do
          subject[key].write("something")
        end.to raise_error("hell")
      end

    end

  end

  [EOFError, Errno::ECONNRESET].each do |retryable_exception|

    context "when a transient #{retryable_exception} occurs" do

      before do
        allow(Net::HTTP).to receive(:start) do
          allow(Net::HTTP).to receive(:start).and_call_original
          fail retryable_exception, "interruptus connecti"
        end
      end

      it "retries and recovers" do
        subject["foo"].write("bar")
        expect(subject["foo"].read).to eq("bar")
      end

    end

    context "when #{retryable_exception} exceptions keep happening" do

      before do
        allow(Net::HTTP).to receive(:start) do
          fail retryable_exception, "interruptus connecti"
        end
      end

      it "raises the final exception" do
        expect do
          subject["anything"].exists?
        end.to raise_error(retryable_exception)
      end

    end

  end

  context "when the hostname can't be resolved" do

    before do
      allow(Net::HTTP).to receive(:start) do
        fail SocketError, "getaddrinfo: nodename nor servname provided, or not known"
      end
    end

    it { is_expected.not_to be_available }

  end

  context "when HTTP server cannot be contacted" do

    before do
      allow(Net::HTTP).to receive(:start) do
        fail Errno::ECONNREFUSED, "Connection refused - connect(2)"
      end
    end

    it { is_expected.not_to be_available }

  end

  context "when the base_uri does not include a trailing slash" do

    subject do
      described_class.new("http://#{http_storage_host}/prefix")
    end

    it "appends a trailing slash" do
      expect(subject.base_uri.to_s).to eq("http://#{http_storage_host}/prefix/")
    end

  end

  context "when the base_uri does include a trailing slash" do

    subject do
      described_class.new("http://#{http_storage_host}/prefix/")
    end

    it "does not append another" do
      expect(subject.base_uri.to_s).to eq("http://#{http_storage_host}/prefix/")
    end

  end

  it "can be created with a URI" do
    store = described_class.new(URI("http://#{http_storage_host}/prefix/"))
    expect(store.base_uri.to_s).to eq("http://#{http_storage_host}/prefix/")
  end

end
