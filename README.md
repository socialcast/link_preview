link_preview
==============

Generate an [oEmbed](http://oembed.com/) response for any URL.

Usage
------

```ruby
content = LinkPreview.fetch(url)
content.as_oembed
```

Serialize content:
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

Installation
-------------
```shell
gem install link_preview
```

Configuration
--------------
TODO

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
