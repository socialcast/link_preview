[![Build Status](https://secure.travis-ci.org/socialcast/link_preview.png?branch=master)](http://travis-ci.org/socialcast/link_preview) 
[![Code Climate](https://codeclimate.com/github/socialcast/link_preview.png)](https://codeclimate.com/github/socialcast/link_preview)

link_preview
==============

Generate an [oEmbed](http://oembed.com/) response for any URL.

Usage
------

```ruby
content = LinkPreview.fetch(url)
content.as_oembed
```

Serialize content sources:
```ruby
content.sources
```

Load previous content via sources:
```ruby
previous_content = LinkPreview.load_content(url, options, content.sources)
```

Features
--------
- Designed to make the minimal number of HTTP requests to generate a preview
- Configurable via [Faraday](https://github.com/lostisland/faraday) middleware
- Battletested on wide variety of URLs and HTML in the wild
- Includes test helper for stubbing `LinkPreview::Content`

Installation
-------------
```shell
gem install link_preview
```

Configuration
--------------
LinkPreview is configured via [`Faraday`](https://github.com/lostisland/faraday) with some additional middleware:

```ruby
# $RAILS_ROOT/config/initializer/link_preview.rb

# Cache responses in Rails.cache
class HTTPCache < Faraday::Middleware
  CACHE_PREFIX = name
  EXPIRES_IN = 10.minutes

  def call(env)
    url = env[:url].to_s
    Rails.cache.fetch("#{CACHE_PREFIX}::#{url}", :expires_in => EXPIRES_IN) do
      @app.call(env)
    end
  end
end

# Report unknown exceptions to Airbrake
module ErrorHandler
  IGNORED_EXCEPTIONS = [
    IOError,
    SocketError,
    Timeout::Error,
    Errno::ECONNREFUSED,
    Errno::ECONNRESET,
    Errno::EHOSTUNREACH,
    Errno::ENETUNREACH,
    Errno::ETIMEDOUT,
    Net::ProtocolError,
    Net::NetworkTimeoutError,
    OpenSSL::SSL::SSLError
  ]

  class << self
    def error_handler(e)
      case e
      when *IGNORED_EXCEPTIONS
        # Ignore
      else
        Airbrake.notify_or_ignore(e)
      end
    end
  end
end

LinkPreview.configure do |config|
  config.http_adapter            = Faraday::Adapter::NetHttp
  config.max_requests            = 10
  config.follow_redirects        = true
  config.middleware              = HTTPCache
  config.error_handler           = ErrorHandler.method(:error_handler)
end
```

Contributing
--------------
* Fork the project
* Fix the issue
* Add unit tests
* Submit pull request on github

See CONTRIBUTORS.txt for list of project contributors

Copyright
---------
Copyright (c) 2014, VMware, Inc. All Rights Reserved.
See LICENSE.txt for further details.
