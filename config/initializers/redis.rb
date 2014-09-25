#$redis = Redis.new(:host => 'localhost', :port => 6379)
uri = URI.parse(ENV["REDISTOGO_URL"])
$redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)

$redis_rtb = Redis.new(:host => 'rtbtarget.plannto.com', :port => 6379)

$redis_new = Redis.new(:host => "pub-redis-15107.us-east-1-2.2.ec2.garantiadata.com", :port => 15107, :password => "ehFuuSSR0ke8WWlD")

# $redis_rtb = $redis_new = $redis

Resque.redis = $redis
#Resque::Server.use(Rack::Auth::Basic) do |user, password|
#  #password == "secret"
#end
