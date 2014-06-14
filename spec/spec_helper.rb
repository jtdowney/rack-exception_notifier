require 'rack'
require 'rack/exception_notifier'
require 'rack/mock'

Mail.defaults do
  delivery_method :test
end

RSpec.configure do |config|
  config.order = 'random'
end

class TestError < StandardError
end
