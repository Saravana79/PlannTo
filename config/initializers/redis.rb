#$redis = Redis.new(:host => 'localhost', :port => 6379)
uri = URI.parse(ENV["REDISTOGO_URL"])
$redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)

$redis_rtb = Redis.new(:host => '184.73.182.76', :port => 6379, :password => "pLanTto@Rtb")

# $redis_rtb = $redis

Resque.redis = $redis
#Resque::Server.use(Rack::Auth::Basic) do |user, password|
#  #password == "secret"
#end
