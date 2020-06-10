# -*- encoding: utf-8 -*-

require File.expand_path(File.dirname(__FILE__) + '/lib/yandex_translate_diff/version')

Gem::Specification.new do |spec|
  spec.name          = "yandex_translate_diff"
  spec.version       = YandexTranslateDiff::VERSION
  spec.authors       = ["gvterechov"]
  spec.email         = ["123freedom123@mail.ru"]
  spec.executables = ["transl"]
  spec.summary       = %q{Write a short summary, because RubyGems requires one.}
  spec.description   = %q{Write a longer description or delete this line.}
  spec.homepage      = "https://github.com/propimo/yandex_translate_diff"
  spec.license       = "MIT"
  spec.files = Dir["{bin,lib}/**/*", "LICENSE", "README.md"]
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "json_pure", ["~> 1.8"]
  spec.add_runtime_dependency "resource_accessor", ["~> 1.2"]
  spec.add_development_dependency "gemspec_deps_gen", ["~> 1.1"]
  spec.add_development_dependency "gemcutter", ["~> 0.7"]

  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "thor", ["~> 0.19"]

end
