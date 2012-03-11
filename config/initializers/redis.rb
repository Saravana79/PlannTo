$redis = Redis.new(:host => 'localhost', :port => 6379)
#Resque::Server.use(Rack::Auth::Basic) do |user, password|
#  #password == "secret"
#end

