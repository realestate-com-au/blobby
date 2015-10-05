require "blobby/key_constraint"
require "fileutils"
require "forwardable"
require "pathname"
require "tempfile"

module Blobby

  # A BLOB store backed by a file-system.
  #
  class FilesystemStore

    def self.from_uri(uri)
      new(uri.path)
    end

    def initialize(dir, options = {}, &sharding_strategy)
      @dir = Pathname(dir)
      @umask = options[:umask] || File.umask
      @sharding_strategy = sharding_strategy || noop_sharding_strategy
    end

    attr_reader :dir
    attr_reader :umask

    def available?
      dir.directory? && dir.readable? && dir.writable?
    end

    def [](key)
      KeyConstraint.must_allow!(key)
      relative_path = @sharding_strategy.call(key)
      StoredObject.new(dir + relative_path, umask)
    end

    private

    def noop_sharding_strategy
      ->(key) { key }
    end

    class StoredObject

      def initialize(path, umask)
        @path = path
        @umask = umask
      end

      extend Forwardable

      def_delegator :@path, :exist?, :exists?

      def read
        @path.open("rb") do |io|
          if block_given?
            while (chunk = io.read(512))
              yield chunk
            end
            nil
          else
            io.read
          end
        end
      rescue Errno::ENOENT
        nil
      end

      def write(content)
        atomic_create(@path) do |out|
          if content.respond_to?(:read)
            FileUtils.copy_stream(content, out)
          else
            out << content
          end
        end
        nil
      end

      def delete
        FileUtils.rm(@path)
        true
      rescue Errno::ENOENT
        false
      end

      private

      def apply_umask(mode)
        mode & ~@umask
      end

      def using_default_umask?
        @umask == File.umask
      end

      RAND_MAX = ("F" * 10).to_i(16)

      def tmp_name
        format("tmp-%X", rand(RAND_MAX))
      end

      def atomic_create(store_path)
        store_dir = store_path.parent
        tmp_path  = store_dir + tmp_name

        tmp = nil
        begin
          tmp = tmp_path.open(File::CREAT | File::EXCL | File::WRONLY, 0666)
          tmp.binmode
        rescue Errno::ENOENT
          FileUtils.mkdir_p(store_dir.to_s, :mode => apply_umask(0777))
          retry
        end

        begin
          yield tmp
          tmp.chmod(apply_umask(0666)) unless using_default_umask?
        ensure
          tmp.close
        end

        first_try = true
        begin
          tmp_path.rename(store_path)
        rescue Errno::ESTALE
          raise unless first_try
          first_try = false
          now = Time.now
          File.utime(now, now, store_dir.to_s)
          retry
        end
      end

    end

  end

end
