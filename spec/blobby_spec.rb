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

    context "with 'mem:'" do

      it "creates an InMemoryStore" do
        store = Blobby.store("mem:")
        expect(store).to be_a(Blobby::InMemoryStore)
      end

    end

  end

end
