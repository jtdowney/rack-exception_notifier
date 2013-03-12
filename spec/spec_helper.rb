require 'rack/exception_notifier'
require 'rack/mock'

Mail.defaults do
  delivery_method :test
end

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.order = 'random'
end

class TestError < StandardError
end
