require 'spec_helper'

describe Rack::ExceptionNotifier do
  before(:each) do
    Mail::TestMailer.deliveries.clear
  end

  let(:good_app) { lambda { |env| [200, {}, ['']] } }
  let(:bad_app) { lambda { |env| raise TestError, 'Test Message' } }
  let(:env) { Rack::MockRequest.env_for("/foo", :method => 'GET') }
  let(:env_with_body) { Rack::MockRequest.env_for("/foo", :method => 'POST', :input => StringIO.new('somethingspecial')) }

  describe 'initialize' do
    it 'requires a to option' do
      expect do
        Rack::ExceptionNotifier.new(good_app, {})
      end.to raise_error(ArgumentError, 'to address is required')
    end

    it 'passes rack lint' do
      lint_app = Rack::Lint.new(bad_app)
      expect do
        app = Rack::ExceptionNotifier.new(
          lint_app,
          :to => 'bar@example.com',
          :from => 'noreply@example.com',
          :subject => 'testing - %s'
        )
        app.call(env_with_body)
      end.to raise_error(TestError)
    end
  end

  describe 'call' do
    it 'does not send mail on success' do
      notifier = Rack::ExceptionNotifier.new(good_app, :to => 'bar@example.com', :from => 'noreply@example.com', :subject => 'testing - %s')
      notifier.call(env)
      expect(Mail::TestMailer.deliveries).to be_empty
    end

    it 'sends mail on exceptions' do
      notifier = Rack::ExceptionNotifier.new(bad_app, :to => 'bar@example.com', :from => 'noreply@example.com', :subject => 'testing - %s')
      expect do
        notifier.call(env)
      end.to raise_error(TestError)

      mail = Mail::TestMailer.deliveries.first
      expect(mail.to).to eq(['bar@example.com'])
      expect(mail.from).to eq(['noreply@example.com'])
      expect(mail.subject).to eq('testing - Test Message')
    end

    it 'sends mail as user by default' do
      notifier = Rack::ExceptionNotifier.new(bad_app, :to => 'bar@example.com', :subject => 'testing - %s')
      expect do
        notifier.call(env)
      end.to raise_error(TestError)

      mail = Mail::TestMailer.deliveries.first
      expect(mail.from).to eq([ENV['USER']])
    end

    it 'does not include body by default' do
      notifier = Rack::ExceptionNotifier.new(bad_app, :to => 'bar@example.com', :from => 'noreply@example.com', :subject => 'testing - %s')
      expect do
        notifier.call(env_with_body)
      end.to raise_error(TestError)

      mail = Mail::TestMailer.deliveries.first
      expect(mail.body.raw_source).not_to include('Request Body')
    end

    it 'does not include body if not present in request' do
      notifier = Rack::ExceptionNotifier.new(bad_app, :to => 'bar@example.com', :from => 'noreply@example.com', :subject => 'testing - %s', :include_body => true)
      expect do
        notifier.call(env)
      end.to raise_error(TestError)

      mail = Mail::TestMailer.deliveries.first
      expect(mail.body.raw_source).not_to include('Request Body')
      expect(mail.body.raw_source).not_to include('rack.input')
      expect(mail.body.raw_source).not_to include('rack.request.form_')
    end

    it 'includes the body if configured' do
      notifier = Rack::ExceptionNotifier.new(bad_app, :to => 'bar@example.com', :from => 'noreply@example.com', :subject => 'testing - %s', :include_body => true)
      expect do
        notifier.call(env_with_body)
      end.to raise_error(TestError)

      mail = Mail::TestMailer.deliveries.first
      expect(mail.body.raw_source).to include('somethingspecial')
      expect(mail.body.raw_source).to include('somethingspecial')
    end

    it 'includes reply-to if configured' do
      notifier = Rack::ExceptionNotifier.new(bad_app, :to => 'bar@example.com', :from => 'noreply@example.com', :reply_to => 'replyto@example.com', :subject => 'testing - %s')
      expect do
        notifier.call(env_with_body)
      end.to raise_error(TestError)

      mail = Mail::TestMailer.deliveries.first
      expect(mail.reply_to).to eq(['replyto@example.com'])
    end

    it 'does not include reply-to if not configured' do
      notifier = Rack::ExceptionNotifier.new(bad_app, :to => 'bar@example.com', :from => 'noreply@example.com', :subject => 'testing - %s')
      expect do
        notifier.call(env_with_body)
      end.to raise_error(TestError)

      mail = Mail::TestMailer.deliveries.first
      expect(mail.reply_to).to be_nil
    end
  end
end
