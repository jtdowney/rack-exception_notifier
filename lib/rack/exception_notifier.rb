require 'erb'
require 'mail'

module Rack
  class ExceptionNotifier
    def initialize(app, options)
      default_options = {
        :to => nil,
        :from => ENV['USER'] || 'rack@localhost',
        :subject => '[ERROR] %s'
      }
      @app = app
      @options = default_options.merge(options)
      @template = ERB.new(Template)
    end

    def call(env)
      @app.call(env)
    rescue => e
      _send_notification(e, env)
      raise
    end

    def _send_notification(exception, env)
      mail = Mail.new
      mail.to(@options[:to])
      mail.from(@options[:from])
      mail.subject(@options[:subject] % [exception.to_s])
      mail.body(@template.result(binding))
      mail.deliver!
    end

    def _extract_body(env)
      io = env['rack.input']
      io.rewind if io.respond_to?(:rewind)
      contents = io.read
      if contents.empty?
        false
      else
        contents
      end
    end

    Template = (<<-'EMAIL').gsub(/^ {4}/, '')
    A <%= exception.class.to_s %> occured: <%= exception.to_s %>
    <% if body = _extract_body(env) %>

    ===================================================================
    Request Body:
    ===================================================================

    <%= body.gsub(/^/, '  ') %>
    <% end %>

    ===================================================================
    Rack Environment:
    ===================================================================

      PID:                     <%= $$ %>
      PWD:                     <%= Dir.getwd %>

      <%= env.to_a.
        sort{|a,b| a.first <=> b.first}.
        map{ |k,v| "%-25s%p" % [k+':', v] }.
        join("\n  ") %>

    <% if exception.respond_to?(:backtrace) %>
    ===================================================================
    Backtrace:
    ===================================================================

      <%= exception.backtrace.join("\n  ") %>
    <% end %>
    EMAIL
  end
end
