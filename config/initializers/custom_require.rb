%w{custom_acts_as_follower authentication reputation ext/string addressable/uri resque-retry resque/failure/redis xmlsimple}.each { |each_val| require each_val }

if Rails.env.production?
  ENV['HEROKU_USER'] = "siva@plannto.com"
  ENV['HEROKU_PASSWORD'] = "sivaplannto"
  ENV["HEROKU_APP"] = "plannto"
  # ENV["MONGOLAB_URI"] = "mongodb://planntonew:planntonew@ds063780-a0.mongolab.com:63780,ds063780-a1.mongolab.com:63780/heroku_app4176992"
  ENV["MONGOLAB_URI"] = "mongodb://planntonew:planntonew@ds051061-a0.mongolab.com:51061,ds051061-a1.mongolab.com:51061/planntonew"

  require "#{Rails.root}/lib/heroku_resque_auto_scale.rb"

  APICache.store = APICache::DalliStore.new(Dalli::Client.new(ENV["MEMCACHIER_SERVERS"].split(","), {:username => ENV["MEMCACHIER_USERNAME"], :password => ENV["MEMCACHIER_PASSWORD"]}))
end

Resque::Failure::MultipleWithRetrySuppression.classes = [Resque::Failure::Redis]
Resque::Failure.backend = Resque::Failure::MultipleWithRetrySuppression