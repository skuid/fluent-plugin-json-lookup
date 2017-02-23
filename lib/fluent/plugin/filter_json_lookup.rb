require 'fluent/filter'
require 'yajl'

module Fluent
  class JsonLookupFilter < Filter
    Fluent::Plugin.register_filter('json_lookup', self)

    config_param :lookup_key,
                 :string,
                 default: nil,
                 desc: <<-DESC
The `lookup_key` is used in looking up the contents of the `json_key`.
    DESC

    config_param :use_lookup_key_value,
                 :bool,
                 default: true,
                 desc: <<-DESC
When `use_lookup_key_value` is set to `true`, the plugin performs the lookup
using `lookup_key`'s value, rather than a hard-coded value.
    DESC

    config_param :json_key,
                 :string,
                 default: nil,
                 desc: 'The `json_key`` is a key that contains a string of json.'

    config_param :remove_json_key,
                 :bool,
                 default: false,
                 desc: 'Remove the `json_key` from each record. Defaults to false.'

    BUILTIN_CONFIGURATIONS = %w(
      type @type log_level @log_level id @id lookup_key json_key
      use_lookup_key_value remove_json_key
    ).freeze

    def configure(conf)
      super

      conf.each_pair do |k, v|
        unless BUILTIN_CONFIGURATIONS.include?(k)
          conf.key(k)
          log.warn "Extra key provided! Ignoring '#{k} #{v}'"
        end
      end

      # GC.start
    end

    def deserialize_and_lookup(content, lookup)
      values = {}
      begin
        deserialized = Yajl.load(content)
        if deserialized.is_a?(Hash) && deserialized.key?(lookup) && deserialized[lookup].is_a?(Hash)
          values = deserialized[lookup]
        end
      rescue Yajl::ParseError
        log.error "Error in plugin json_lookup, error parsing json_key's value #{content}'"
      end
      values
    end

    def filter_stream(_tag, es)
      new_es = MultiEventStream.new
      es.each do |time, record|
        values = {}
        if record.key?(@json_key)
          lookup = @use_lookup_key_value ? record[@lookup_key] : @lookup_key
          if record[@json_key][0] == '{'
            values = deserialize_and_lookup(record[@json_key], lookup)
          end
        end
        record.merge!(values)

        record.delete(@json_key) if @remove_json_key && record.key?(@json_key)

        new_es.add(time, record)
      end
      new_es
    end
  end
end
