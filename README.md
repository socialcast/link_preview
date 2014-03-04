Usage
------

Generate link_preview content from URL
```ruby
content = LinkPreview.fetch(url)
content.as_oembed
```

Load previous link_preview content via sources
```ruby
previous_content = LinkPreview.load_content(url, options, content.sources)
```
