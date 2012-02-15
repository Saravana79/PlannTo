# Load the rails application
require File.expand_path('../application', __FILE__)
require 'rails_sql_views'
ActionMailer::Base.smtp_settings = {
  :address              => "smtp.gmail.com",
  :port                 => 587,
  :domain               => "plannto.com",
  :user_name            => "plannto.test",
  :password             => "planntotest",
  :authentication       => "plain",
  :enable_starttls_auto => true
}

# Initialize the rails application
PlanNto::Application.initialize!
