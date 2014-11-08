%w{custom_acts_as_follower authentication reputation ext/string addressable/uri resque-retry resque/failure/redis amazon/ecs}.each { |each_val| require each_val }

# Amazon::Ecs.configure do |options|
#   options[:associate_tag] = 'pla04-21'
#   options[:AWS_access_key_id] = 'AKIAJWDCN4DJWNL2FK5A'
#   options[:AWS_secret_key] = '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'
# end

# require "#{Rails.root}/lib/amazon/ecs"

if Rails.env.production?
  ENV['HEROKU_USER'] = "siva@plannto.com"
  ENV['HEROKU_PASSWORD'] = "sivaplannto"
  ENV["HEROKU_APP"] = "plannto"
  ENV["MONGOLAB_URI"] = "mongodb://heroku_app4176992:2q253r5a1e74dj1kfpifpbk4di@ds037990.mongolab.com:37990/heroku_app4176992"

  require "#{Rails.root}/lib/heroku_resque_auto_scale.rb"
end

Resque::Failure::MultipleWithRetrySuppression.classes = [Resque::Failure::Redis]
Resque::Failure.backend = Resque::Failure::MultipleWithRetrySuppression