require 'fluent/test'
require 'fluent/plugin/filter_json_lookup'
require 'test/unit'

exit unless defined?(Fluent::Filter)

class JsonLookupFilterTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
    @tag = 'test.tag'
  end

  CONFIG = '
    @type json_lookup
    lookup_key kubernetes_container_name
    json_key kubernetes_annotations_fluentd_org/keys
    remove_json_key true
  '.freeze

  def create_driver(conf = CONFIG)
    Fluent::Test::FilterTestDriver.new(Fluent::JsonLookupFilter, @tag).configure(conf, true)
  end

  def test_lookup_exists
    d = create_driver

    d.run do
      d.emit(
        'kubernetes_container_name' => 'nginx',
        'kubernetes_annotations_fluentd_org/keys' => '{"nginx": {"es_type": "nginx", "es_index": "fluentd-nginx-"}, "webapp": {"es_type": "application", "es_index": "fluentd-app-"}}'
      )
      d.emit(
        'kubernetes_container_name' => 'webapp',
        'kubernetes_annotations_fluentd_org/keys' => '{"nginx": {"es_type": "nginx", "es_index": "fluentd-nginx-"}, "webapp": {"es_type": "application", "es_index": "fluentd-app-"}}'
      )
    end

    assert_equal [
      { 'kubernetes_container_name' => 'nginx', 'es_type' => 'nginx', 'es_index' => 'fluentd-nginx-' },
      { 'kubernetes_container_name' => 'webapp', 'es_type' => 'application', 'es_index' => 'fluentd-app-' }
    ], d.filtered_as_array.map(&:last)
  end

  def test_lookup_exists_keep_key
    d = create_driver '
      @type json_lookup
      lookup_key kubernetes_container_name
      json_key kubernetes_annotations_fluentd_org/keys
    '

    d.run do
      d.emit(
        'kubernetes_container_name' => 'nginx',
        'kubernetes_annotations_fluentd_org/keys' => '{"nginx": {"t": "nginx", "i": "fluentd-nginx-"}, "webapp": {"t": "application", "i": "fluentd-app-"}}'
      )
      d.emit(
        'kubernetes_container_name' => 'webapp',
        'kubernetes_annotations_fluentd_org/keys' => '{"nginx": {"t": "nginx", "i": "fluentd-nginx-"}, "webapp": {"t": "application", "i": "fluentd-app-"}}'
      )
    end

    assert_equal [
      {
        'i' => 'fluentd-nginx-',
        'kubernetes_container_name' => 'nginx',
        'kubernetes_annotations_fluentd_org/keys' => '{"nginx": {"t": "nginx", "i": "fluentd-nginx-"}, "webapp": {"t": "application", "i": "fluentd-app-"}}',
        't' => 'nginx'
      },
      {
        'i' => 'fluentd-app-',
        'kubernetes_container_name' => 'webapp',
        'kubernetes_annotations_fluentd_org/keys' => '{"nginx": {"t": "nginx", "i": "fluentd-nginx-"}, "webapp": {"t": "application", "i": "fluentd-app-"}}',
        't' => 'application'
      }
    ], d.filtered_as_array.map(&:last)
  end

  def test_lookup_exists_hard_code
    d = create_driver '
      @type json_lookup
      lookup_key hardcoded
      json_key kubernetes_annotations_fluentd_org/keys
      use_lookup_key_value false
      remove_json_key true
    '

    d.run do
      d.emit(
        'kubernetes_container_name' => 'nginx',
        'kubernetes_annotations_fluentd_org/keys' => '{"hardcoded": {"t": "hardcoded", "i": "fluentd-hardcoded-"}, "webapp": {"t": "application", "i": "fluentd-app-"}}'
      )
      d.emit(
        'kubernetes_container_name' => 'webapp',
        'kubernetes_annotations_fluentd_org/keys' => '{"nginx": {"t": "nginx", "i": "fluentd-nginx-"}, "webapp": {"t": "application", "i": "fluentd-app-"}}'
      )
    end

    assert_equal [
      {
        'i' => 'fluentd-hardcoded-',
        'kubernetes_container_name' => 'nginx',
        't' => 'hardcoded'
      },
      {
        'kubernetes_container_name' => 'webapp'
      }
    ], d.filtered_as_array.map(&:last)
  end

  def test_lookup_absent
    d = create_driver

    d.run do
      d.emit(
        'kubernetes_container_name' => 'nginx',
        'kubernetes_annotations_fluentd_org/keys' => '{"webapp": {"t": "application", "i": "fluentd-app-"}}'
      )
      d.emit(
        'kubernetes_container_name' => 'webapp',
        'kubernetes_annotations_fluentd_org/keys' => '{"nginx": {"t": "nginx", "i": "fluentd-nginx-"}}'
      )
      d.emit(
        'other_key' => 'value',
        'kubernetes_annotations_fluentd_org/keys' => '{"nginx": {"t": "nginx", "i": "fluentd-nginx-"}}'
      )
      d.emit('kubernetes_container_name' => 'webapp')
    end

    assert_equal [
      { 'kubernetes_container_name' => 'nginx' },
      { 'kubernetes_container_name' => 'webapp' },
      { 'other_key' => 'value' },
      { 'kubernetes_container_name' => 'webapp' }
    ], d.filtered_as_array.map(&:last)
  end

  def test_lookup_malformed
    d = create_driver

    d.run do
      d.emit(
        'kubernetes_container_name' => 'nginx',
        'kubernetes_annotations_fluentd_org/keys' => '{{"webapp": {"t": "application", "i": "fluentd-app-"}}'
      )
      d.emit(
        'kubernetes_container_name' => 'nginx',
        'kubernetes_annotations_fluentd_org/keys' => '{"nginx": ["t", "nginx", "i", "fluentd-nginx-"]}'
      )
    end

    assert_equal [
      { 'kubernetes_container_name' => 'nginx' },
      { 'kubernetes_container_name' => 'nginx' }
    ], d.filtered_as_array.map(&:last)
  end
end
