require "blobby"

describe Blobby do

  describe ".store" do

    context "with an absolute file path" do

      it "creates a FilesystemStore" do
        store = Blobby.store("/data")
        expect(store).to be_a(Blobby::FilesystemStore)
        expect(store.dir.to_s).to eq("/data")
      end

    end

    context "with a file:// URI" do

      it "creates a FilesystemStore" do
        store = Blobby.store("file:///data")
        expect(store).to be_a(Blobby::FilesystemStore)
        expect(store.dir.to_s).to eq("/data")
      end

    end

    context "with an http:// URI" do

      it "creates a HttpStore" do
        store = Blobby.store("http://storage.com/data/")
        expect(store).to be_a(Blobby::HttpStore)
        expect(store.base_uri.host).to eq("storage.com")
        expect(store.base_uri.path).to eq("/data/")
      end

    end

    context "with an https:// URI" do

      it "creates a HttpStore" do
        store = Blobby.store("https://storage.com/data/")
        expect(store).to be_a(Blobby::HttpStore)
        expect(store.base_uri.scheme).to eq("https")
        expect(store.base_uri.host).to eq("storage.com")
        expect(store.base_uri.path).to eq("/data/")
      end

    end

    context "with 'mem:'" do

      it "creates an InMemoryStore" do
        store = Blobby.store("mem:")
        expect(store).to be_a(Blobby::InMemoryStore)
      end

    end

  end

end
