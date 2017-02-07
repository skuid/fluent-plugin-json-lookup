# fluent-plugin-json-lookup

[![Build Status](https://travis-ci.org/skuid/fluent-plugin-json-lookup.svg?branch=master)](https://travis-ci.org/skuid/fluent-plugin-json-lookup)
[![Gem Version](https://badge.fury.io/rb/fluent-plugin-json-lookup.svg)](https://badge.fury.io/rb/fluent-plugin-json-lookup)

Fluentd filter plugin for looking up json objects from messages.

## Installation

Use RubyGems:

    gem install fluent-plugin-json-lookup

## Configuration

### Use  of the `json_lookup` filter.

```
<filter pattern>
  @type json_lookup
  lookup_key kubernetes_container_name
  json_key kubernetes_annotations_fluentd_org/keys
  remove_json_key true
</filter>
```

If following record is passed:

```json
{
    "kubernetes_container_name" : "nginx",
    "kubernetes_annotations_fluentd_org/keys" : "{\"nginx\": {\"es_type\": \"nginx\", \"es_index\": \"fluentd-nginx-\"}, \"webapp\": {\"es_type\": \"application\", \"es_index\": \"fluentd-app-\"}}"
}
```

then the emitted record would be:

```json
{
    "kubernetes_container_name": "nginx",
    "es_type": "nginx",
    "es_index": "fluentd-nginx-"
}
```

### Alternate use of the `json_lookup` filter.

```
<filter pattern>
  @type json_lookup
  lookup_key nginx
  json_key kubernetes_annotations_fluentd_org/keys
  use_lookup_key_value false
  remove_json_key false
</filter>
```

If following record is passed:

```json
{
    "kubernetes_container_name" : "arbitrary",
    "kubernetes_annotations_fluentd_org/keys" : "{\"nginx\": {\"es_type\": \"nginx\", \"es_index\": \"fluentd-nginx-\"}}"
}
```

then the emitted record would be:

```json
{
    "kubernetes_container_name" : "arbitrary",
    "kubernetes_annotations_fluentd_org/keys" : "{\"nginx\": {\"es_type\": \"nginx\", \"es_index\": \"fluentd-nginx-\"}}",
    "es_type": "nginx",
    "es_index": "fluentd-nginx-"
}
```

If the value of `lookup_key` is not present, not a JSON object, or is malformed
JSON, the message will pass through unaltered (unless `remove_json_key` is set
to true).

## `json_key`

The `json_key` specifies which log value to parse as json and perform a lookup
in.

## `lookup_key`

The lookup key is used to specify the key within the deserialized `json_key`'s
value.

## `use_lookup_key_value`

When `use_lookup_key_value` is set to true, the value of `lookup_key` is used,
rather then the configuration key's name. Defaults to `true`.

## `remove_json_key`

When set to `true`, remove's the `json_key` from the message. Defaults to
`false`.

## License

MIT (See [License](/LICENSE))
