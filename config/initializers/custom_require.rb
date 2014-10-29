%w{custom_acts_as_follower authentication reputation ext/string addressable/uri resque-retry}.each { |each_val| require each_val }

if Rails.env.production?
  ENV['HEROKU_USER'] = "siva@plannto.com"
  ENV['HEROKU_PASSWORD'] = "sivaplannto"
  ENV["HEROKU_APP"] = "plannto"

  require "#{Rails.root}/lib/heroku_resque_auto_scale.rb"
end