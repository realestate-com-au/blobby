# Blobby

This gem provides a standard interface for storing big chunks of data.

## Usage

It supports popular BLOBs operations such as reading:

    store["key"].read

writing:

    store["key"].write("some content")
    store["key"].write(File.open("kitty.png"))

checking for existance:

    store["key"].exists?

and even deleting:

    store["key"].delete

This gem provides several "store" implementations:

    # on disk
    Blobby::FilesystemStore.new("/big/data")

    # in memory
    Blobby::InMemoryStore.new

    # generic HTTP
    Blobby::HttpStore.new("http://attachment-store/objects")

    # fake success
    Blobby::FakeSuccessStore.new

Other gems provide additional implementations:

    # gem "blobby-s3"
    Blobby::S3Store.new("mybucket")
