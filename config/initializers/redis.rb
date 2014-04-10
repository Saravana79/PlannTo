#$redis = Redis.new(:host => 'localhost', :port => 6379)
uri = URI.parse(ENV["REDISTOGO_URL"])
$redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)

$redis_rtb = Redis.new(:host => '54.83.203.184', :port => 6379)

# $redis_rtb = $redis

Resque.redis = $redis
#Resque::Server.use(Rack::Auth::Basic) do |user, password|
#  #password == "secret"
#end
