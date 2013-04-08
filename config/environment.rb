# Load the rails application
require File.expand_path('../application', __FILE__)
require 'rails_sql_views'
ActionMailer::Base.smtp_settings = {
:address => "smtpout.asia.secureserver.net",
:port => 80,
:domain => "plannto.com",
:user_name => "admin@plannto.com",
:password => "plannto",
:authentication => :plain,
:enable_starttls_auto => false,
:openssl_verify_mode => 'none'
}
require 'aws/s3'
AWS::S3::DEFAULT_HOST = "s3-ap-southeast-1.amazonaws.com" # if using sg buckets

# Initialize the rails application
PlanNto::Application.initialize!

