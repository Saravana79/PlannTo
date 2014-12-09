%w{custom_acts_as_follower authentication reputation ext/string addressable/uri resque-retry resque/failure/redis xmlsimple}.each { |each_val| require each_val }

if Rails.env.production?
  ENV['HEROKU_USER'] = "siva@plannto.com"
  ENV['HEROKU_PASSWORD'] = "sivaplannto"
  ENV["HEROKU_APP"] = "plannto"
  # ENV["MONGOLAB_URI"] = "mongodb://heroku_app32111901:fdtkm30k97nh3phn51utncongs@ds063140.mongolab.com:63140/heroku_app32111901"

  require "#{Rails.root}/lib/heroku_resque_auto_scale.rb"
end

Resque::Failure::MultipleWithRetrySuppression.classes = [Resque::Failure::Redis]
Resque::Failure.backend = Resque::Failure::MultipleWithRetrySuppression