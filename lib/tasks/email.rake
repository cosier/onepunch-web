namespace :email do
  desc "Send a test email to verify SMTP configuration"
  task test: :environment do
    puts "Sending test email..."

    # Get application version and stats
    rails_version = Rails.version
    ruby_version = RUBY_VERSION
    app_env = Rails.env

    # Create and send test email
    ActionMailer::Base.mail(
      from: "robot@onepunch.work",
      to: "bailey.cosier@gmail.com",
      subject: "Hi, Bailey - OnePunch is ready.",
      body: <<~EMAIL
        Hello Bailey,

        Your OnePunch application is up and running!

        System Information:
        -------------------
        • Environment: #{app_env}
        • Rails Version: #{rails_version}
        • Ruby Version: #{ruby_version}
        • SMTP Host: #{ENV['SMTP_ADDRESS']}
        • SMTP Domain: #{ENV['SMTP_DOMAIN']}
        • Time: #{Time.current.strftime("%B %d, %Y at %I:%M %p %Z")}

        This test email confirms that your AWS SES SMTP integration is working correctly.

        Cheers,
        OnePunch Robot 🤖
      EMAIL
    ).deliver_now

    puts "✓ Test email sent successfully to bailey.cosier@gmail.com"
  rescue => e
    puts "✗ Failed to send test email: #{e.message}"
    puts e.backtrace.first(5)
  end
end