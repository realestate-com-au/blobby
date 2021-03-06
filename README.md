# Blobby

[![Build Status](https://travis-ci.org/realestate-com-au/blobby.svg?branch=master)](https://travis-ci.org/realestate-com-au/blobby)

This gem provides a standard interface for storing big chunks of data.

## Usage

It supports popular BLOB operations such as reading:

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

  * ["blobby-s3"](https://github.com/realestate-com-au/blobby-s3)

`Blobby.store` provides a convenient way to construct an appropriate
implementation, given a URI (or psuedo-URI):

    Blobby.store("file:///tmp")
    # => #<Blobby::FilesystemStore ...>

    Blobby.store("mem:")
    # => #<Blobby::InMemoryStore ...>

    Blobby.store("http://storage.com/mystuff/")
    # => #<Blobby::HttpStore ...>
