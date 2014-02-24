require 'link_preview'

module LinkPreview
  class NullCrawler
    def initialize(config, options = {})
    end

    def enqueue!(uri, priority = :default)
    end

    def dequeue!(priority_order = [])
    end

    def success?
      true
    end

    def finished?
      true
    end

    def full?
      false
    end
  end
end
