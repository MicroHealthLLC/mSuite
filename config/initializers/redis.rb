if Rails.env.test?
  require 'mock_redis'
  $redis = MockRedis.new
else
  $redis = Redis.new
end


