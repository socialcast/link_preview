require 'link_preview/http_client'

module LinkPreview
  class Configuration
    attr_accessor :http_client
    attr_accessor :max_redirects
    attr_accessor :max_requests
    attr_accessor :timeout
    attr_accessor :open_timeout
    attr_accessor :error_handler

    def max_redirects
      @max_redirects || 3
    end

    def max_requests
      @max_requests || 10
    end

    def timeout
      @timeout || 5 # seconds
    end

    def open_timeout
      @open_timeout || 2 # seconds
    end

    def error_handler
      @error_handler ||= Proc.new() { |_| }
    end

    def http_client
      @http_client ||= HTTPClient.new(self)
    end

    def http_client=(http_client)
      @http_client = http_client
    end
  end
end
