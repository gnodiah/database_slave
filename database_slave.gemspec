path = File.expand_path("../lib", __FILE__)
$:.unshift(path) unless $:.include? path
require 'database_slave/version'

Gem::Specification.new do |gem|
  gem.name                  = 'database_slave'
  gem.version               = DatabaseSlave::VERSION
  gem.summary               = "Provide master and slave databases support for Rails applications."
  gem.description           = "Provide master and slave databases support for Rails applications."
  gem.authors               = ["Hayden Wei"]
  gem.email                 = 'haidongrun@gmail.com'
  gem.homepage              = 'https://github.com/Gnodiah/database_slave'
  gem.license               = 'MIT'
  gem.files                 = `git ls-files`.split("\n")
  gem.required_ruby_version = '>= 2.0.0'
end
