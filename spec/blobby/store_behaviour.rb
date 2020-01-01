# frozen_string_literal: true

require "spec_helper"

require "rspec"

module Blobby
  module Store
  end
end

shared_examples_for Blobby::Store do

  let(:key) { "KEY" }
  let(:content) { "CONTENT" }

  it "is available" do
    expect(subject).to be_available
  end

  context "for a valid key" do

    let(:stored_object) { subject[key] }

    context "when nothing has been stored" do

      describe "#exists?" do
        it "is false" do
          expect(stored_object).not_to exist
        end
      end

      describe "#read" do
        it "returns nil" do
          expect(stored_object.read).to be_nil
        end
      end

      describe "#delete" do
        it "returns false" do
          expect(stored_object.delete).to eq(false)
        end
      end

    end

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

        it "returns the content" do
          expect(stored_object.read).to eq(content)
        end

        context "with a block" do

          before do
            @chunks = []
            @rval = stored_object.read do |chunk|
              @chunks << chunk
            end
          end

          it "yields the content in chunks" do
            expect(@chunks.join).to eq(content)
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

        it "removes the object" do
          stored_object.delete
          expect(stored_object).not_to exist
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
            stored_content = stored_object.read
            expect(stored_content.encoding.name).to eq("ASCII-8BIT")
            expect(stored_content.force_encoding("UTF-8")).to eq(content)
          end

        end

      end

    end

    describe "#write" do

      it "returns nil" do
        expect(stored_object.write(content)).to be_nil
      end

      context "with a stream" do

        before do
          stored_object.write(StringIO.new(content))
        end

        it "writes the content of the stream" do
          expect(stored_object.read).to eq(content)
        end

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
