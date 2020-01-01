# frozen_string_literal: true

$LOAD_PATH << File.expand_path("lib", __dir__)
require "blobby/version"

Gem::Specification.new do |gem|

  gem.authors       = ["Mike Williams"]
  gem.email         = ["mdub@dogbiscuit.org"]
  gem.summary       = "Various ways of storing BLOBs"
  gem.homepage      = "https://github.com/realestate-com-au/blobby"

  gem.files         = `git ls-files`.split($OUTPUT_RECORD_SEPARATOR)
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "blobby"
  gem.require_paths = ["lib"]
  gem.version       = Blobby::VERSION

end
