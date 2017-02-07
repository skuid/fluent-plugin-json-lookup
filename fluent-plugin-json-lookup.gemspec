# encoding: utf-8
$LOAD_PATH.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |gem|
  gem.name        = 'fluent-plugin-json-lookup'
  gem.description = 'Filter plugin for looking up a json object out of a record'
  gem.homepage    = 'https://github.com/skuid/fluent-plugin-json-lookup'
  gem.summary     = gem.description
  gem.version     = File.read('VERSION').strip
  gem.authors     = ['Micah Hausler']
  gem.email       = 'micah@skuid.com'
  gem.has_rdoc    = false
  gem.license     = 'MIT'
  gem.files       = `git ls-files`.split("\n")
  gem.test_files  = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.executables = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  gem.require_paths = ['lib']

  gem.add_dependency 'fluentd', ['>= 0.10.58', '< 2']
  gem.add_runtime_dependency 'yajl-ruby', '~> 1.0'
  gem.add_development_dependency 'rake', '>= 0.9.2'
  gem.add_development_dependency('test-unit', ['~> 3.1.4'])
end
