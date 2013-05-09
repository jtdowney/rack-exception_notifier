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
  end

  describe 'call' do
    it 'does not send mail on success' do
      notifier = Rack::ExceptionNotifier.new(good_app, :to => 'bar@example.com', :from => 'noreply@example.com', :subject => 'testing - %s')
      notifier.call(env)
      Mail::TestMailer.deliveries.should be_empty
    end

    it 'sends mail on exceptions' do
      notifier = Rack::ExceptionNotifier.new(bad_app, :to => 'bar@example.com', :from => 'noreply@example.com', :subject => 'testing - %s')
      expect do
        notifier.call(env)
      end.to raise_error(TestError)

      mail = Mail::TestMailer.deliveries.first
      mail.to.should == ['bar@example.com']
      mail.from.should == ['noreply@example.com']
      mail.subject.should == 'testing - Test Message'
    end

    it 'sends mail as user by default' do
      notifier = Rack::ExceptionNotifier.new(bad_app, :to => 'bar@example.com', :subject => 'testing - %s')
      expect do
        notifier.call(env)
      end.to raise_error(TestError)

      mail = Mail::TestMailer.deliveries.first
      mail.from.should == [ENV['USER']]
    end

    it 'does not include body by default' do
      notifier = Rack::ExceptionNotifier.new(bad_app, :to => 'bar@example.com', :from => 'noreply@example.com', :subject => 'testing - %s')
      expect do
        notifier.call(env_with_body)
      end.to raise_error(TestError)

      mail = Mail::TestMailer.deliveries.first
      mail.body.raw_source.should_not include('Request Body')
    end

    it 'does not include body if not present in request' do
      notifier = Rack::ExceptionNotifier.new(bad_app, :to => 'bar@example.com', :from => 'noreply@example.com', :subject => 'testing - %s', :include_body => true)
      expect do
        notifier.call(env)
      end.to raise_error(TestError)

      mail = Mail::TestMailer.deliveries.first
      mail.body.raw_source.should_not include('Request Body')
      mail.body.raw_source.should_not include('rack.input')
      mail.body.raw_source.should_not include('rack.request.form_')
    end

    it 'includes the body if configured' do
      notifier = Rack::ExceptionNotifier.new(bad_app, :to => 'bar@example.com', :from => 'noreply@example.com', :subject => 'testing - %s', :include_body => true)
      expect do
        notifier.call(env_with_body)
      end.to raise_error(TestError)

      mail = Mail::TestMailer.deliveries.first
      mail.body.raw_source.should include('somethingspecial')
      mail.body.raw_source.should include('somethingspecial')
    end

    it 'includes reply-to if configured' do
      notifier = Rack::ExceptionNotifier.new(bad_app, :to => 'bar@example.com', :from => 'noreply@example.com', :reply_to => 'replyto@example.com', :subject => 'testing - %s')
      expect do
        notifier.call(env_with_body)
      end.to raise_error(TestError)

      mail = Mail::TestMailer.deliveries.first
      mail.reply_to.should == ['replyto@example.com']
    end

    it 'does not include reply-to if not configured' do
      notifier = Rack::ExceptionNotifier.new(bad_app, :to => 'bar@example.com', :from => 'noreply@example.com', :subject => 'testing - %s')
      expect do
        notifier.call(env_with_body)
      end.to raise_error(TestError)

      mail = Mail::TestMailer.deliveries.first
      mail.reply_to.should be_nil
    end
  end
end
