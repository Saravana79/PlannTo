#$redis = Redis.new(:host => 'localhost', :port => 6379)
uri = URI.parse(ENV["REDISTOGO_URL"])
$redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)

Resque.redis = $redis
#Resque::Server.use(Rack::Auth::Basic) do |user, password|
#  #password == "secret"
#end
