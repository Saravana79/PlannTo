uri = URI.parse(ENV["REDISTOGO_URL"])
REDIS = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)

#$redis = Redis.new(:host => 'localhost', :port => 6379)
#Resque::Server.use(Rack::Auth::Basic) do |user, password|
#  #password == "secret"
#end

