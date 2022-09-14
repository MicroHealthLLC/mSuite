if Rails.env.test?
  require 'mock_redis'
  $redis = MockRedis.new
else
  cable_file = File.join(File.dirname(__FILE__), "../cable.yml")
  yaml_config = ERB.new(IO.read(cable_file)).result
  cable_config = YAML.respond_to?(:unsafe_load) ? YAML.unsafe_load(yaml_config) : YAML.load(yaml_config)
  $redis =   Redis.new( url: cable_config[Rails.env.to_s ]['url'] ||  cable_config['redis']['url'] )
end
