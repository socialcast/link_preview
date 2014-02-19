Usage
------

Simple:
```
link_preview = LinkPreview.fetch(url)
link_preview.as_oembed
# Serialize by converting to JSON
link_preview.as_json
```

Existing Structured Data
```
link_preview = LinkPreview.load(structured_data)
```
