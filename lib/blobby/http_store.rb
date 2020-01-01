# frozen_string_literal: true

require "blobby/key_constraint"
require "net/http"

module Blobby

  # A BLOB store backed by HTTP.
  #
  class HttpStore

    def self.from_uri(uri)
      new(uri)
    end

    def initialize(uri, options = {})
      uri = URI(uri)
      uri = URI("#{uri}/") unless uri.to_s.end_with?("/")
      @base_uri = uri
      @max_retries = options.fetch(:max_retries, 2)
    end

    attr_reader :base_uri
    attr_reader :max_retries

    def available?
      with_http_connection do
        true
      end
    rescue StandardError
      false
    end

    def [](key)
      KeyConstraint.must_allow!(key)
      StoredObject.new(self, key)
    end

    def with_http_connection
      remaining_retry_intervals = retry_intervals(max_retries)
      begin
        Net::HTTP.start(base_uri.host, base_uri.port) do |http|
          yield http, base_uri.path
        end
      rescue *retryable_exceptions => e
        raise e if remaining_retry_intervals.empty?

        sleep(remaining_retry_intervals.shift) && retry
      end
    end

    protected

    def retryable_exceptions
      [EOFError, Errno::ECONNRESET]
    end

    def retry_intervals(count)
      # exponential backoff: [0.5, 1, 2, 4, 8, ...]
      scaling_factor = (0.5 + Kernel.rand * 0.1) # a little random avoids throbbing
      Array.new(count) { |i| (2**i) * scaling_factor }
    end

    # Represents an object in the store.
    class StoredObject

      def initialize(store, key)
        @store = store
        @key = key
      end

      attr_reader :key

      def exists?
        with_http_connection do |http, path|
          response = http.head(path)
          response.code == "200"
        end
      end

      def read(&block)
        with_http_connection do |http, path|
          http.request_get(path) do |response|
            case response
            when Net::HTTPNotFound
              return nil
            when Net::HTTPSuccess
              if block_given?
                response.read_body(&block)
                return nil
              end
              return response.read_body
            end
            response.error!
          end
        end
      end

      def write(content)
        content = if content.respond_to?(:read)
                    content.read
                  else
                    content.dup
                  end
        with_http_connection do |http, path|
          put = Net::HTTP::Put.new(path)
          put.body = content
          put["Content-Type"] = "application/octet-stream"
          response = http.request(put)
          response.error! unless response.is_a?(Net::HTTPSuccess)
          true
        end
        nil
      end

      def delete
        with_http_connection do |http, path|
          delete = Net::HTTP::Delete.new(path)
          response = http.request(delete)
          case response
          when Net::HTTPSuccess
            true
          when Net::HTTPNotFound
            false
          else
            response.error!
          end
        end
      end

      private

      def with_http_connection
        @store.with_http_connection do |http, base_path|
          yield http, base_path + key
        end
      end

    end

  end

end
