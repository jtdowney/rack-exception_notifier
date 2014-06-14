# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift(File.expand_path('../lib', __FILE__))
require 'rack/exception_notifier/version'

Gem::Specification.new do |s|
  s.name        = 'rack-exception_notifier'
  s.version     = Rack::ExceptionNotifier::VERSION
  s.authors     = ['John Downey']
  s.email       = ['jdowney@gmail.com']
  s.homepage    = 'http://github.com/jtdowney/rack-exception_notifier'
  s.license     = 'MIT'
  s.summary     = %q{Rack middleware to send email when exceptions are raised}
  s.description = %q{Rack middleware to send email when exceptions are raised}

  s.files        = Dir.glob('{lib,spec}/**/*.rb') + %w{README.md LICENSE}
  s.test_files   = Dir.glob('spec/**/*')
  s.require_path = 'lib'

  s.add_dependency 'mail', '~> 2.2'

  s.add_development_dependency 'bundler', '~> 1.0'
  s.add_development_dependency 'rack', '1.5.2'
  s.add_development_dependency 'rake', '10.0.4'
  s.add_development_dependency 'rspec', '3.0.0'
end
