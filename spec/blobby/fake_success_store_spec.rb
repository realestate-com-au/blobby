# encoding: UTF-8

require "spec_helper"

require "blobby/fake_success_store"
require "blobby/store_behaviour"

describe Blobby::FakeSuccessStore do

  subject do
    described_class.new
  end

  let(:key) { "KEY" }
  let(:content) { "CONTENT" }

  it "is available" do
    expect(subject).to be_available
  end

  context "for a valid key" do

    let(:stored_object) { subject[key] }

    context "after content has been written" do

      before do
        stored_object.write(content)
      end

      describe "#exists?" do
        it "is true" do
          expect(stored_object).to exist
        end
      end

      describe "#read" do

        it "returns some content" do
          expect(stored_object.read).not_to be_nil
        end

        context "with a block" do

          before do
            @chunks = []
            @rval = stored_object.read do |chunk|
              @chunks << chunk
            end
          end

          it "yields some content in chunks" do
            expect(@chunks.join).not_to be_nil
          end

          it "returns nil" do
            expect(@rval).to be_nil
          end

        end

      end

      describe "#delete" do
        it "returns true" do
          expect(stored_object.delete).to eq(true)
        end
      end
    end

    if "Strings".respond_to?(:encoding)

      context "for UTF-8 content" do

        let(:content) { "SN☃WMAN" }

        before do
          stored_object.write(content)
        end

        describe "#read" do

          it "returns binary data" do
            expect(stored_object.read.encoding.name).to eq("ASCII-8BIT")
          end

        end

      end

    end

    describe "#write" do

      it "returns nil" do
        expect(stored_object.write(content)).to be_nil
      end

    end

  end

  class << self

    def it_allows_keys_containing(description, example_key)
      it "allows keys containing #{description}" do
        expect { subject[example_key] }.not_to raise_error
      end
    end

    def it_disallows_keys_containing(description, example_key)
      it "disallows keys containing #{description}" do
        expect { subject[example_key] }.to raise_error(ArgumentError)
      end
    end

  end

  it_disallows_keys_containing "nil", nil
  it_disallows_keys_containing "blank", ""

  it_allows_keys_containing "slashes", "foo/bar/baz"
  it_allows_keys_containing "selected metacharacters", "@$&*.,;()~"

  it_disallows_keys_containing "spaces", "foo bar"
  it_disallows_keys_containing "tabs", "foo\tbar"
  it_disallows_keys_containing "newlines", "foo\nbar"

  it_disallows_keys_containing "a question mark", "foo?"
  it_disallows_keys_containing "a colon", "foo:blah"

  it_disallows_keys_containing "a leading slash", "/foo"
  it_disallows_keys_containing "a trailing slash", "foo/"
  it_disallows_keys_containing "double slashes", "foo//bar"

end
