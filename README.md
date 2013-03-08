# rack-exception_notifier

Rack-exception_notifier is a piece of simple rack middleware that will rescue exceptions and send email using the mail gem. This gem is based on Rack::MailExceptions in rack-contrib.

## Usage

First include rack-exception_notifier in your Gemfile:

```ruby
gem 'rack-exception_notifier'
```

Next configure the mail gem, by default mail will send email via SMTP to port 25 on localhost. If you would like to change that you can configure the gem according to [their documentation](https://github.com/mikel/mail/).

Then you need to configure rack to use the middleware. Below is an example for sinatra:

```ruby
use Rack::ExceptionNotifier,
  :to => 'me@example.com',
  :from => 'app@example.com',
  :subject => '[ERROR] %s'
```

## License

Rack-exception_notifier is released under the [MIT license](http://www.opensource.org/licenses/MIT).
