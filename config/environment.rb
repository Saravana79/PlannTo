# Load the rails application
require File.expand_path('../application', __FILE__)
require 'rails_sql_views'
ActionMailer::Base.smtp_settings = {
    :address => "smtp.gmail.com",
    :port => 587,
    :domain => "www.plannto.com",
    :user_name => "plannto.test@gmail.com",
    :password => "saravana@6",
    :authentication => :plain,
    :enable_starttls_auto => true,
    :openssl_verify_mode => 'none'
}
# require 'aws/s3'
Aws::S3::DEFAULT_HOST = "s3-ap-southeast-1.amazonaws.com" # if using sg buckets

# Initialize the rails application
PlanNto::Application.initialize!
