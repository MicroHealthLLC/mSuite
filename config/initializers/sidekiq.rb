require 'yaml'

schedule_file = 'config/schedule.yml'

cable_file = File.join(File.dirname(__FILE__), "../cable.yml")
yaml_config = ERB.new(IO.read(cable_file)).result
cable_array = YAML.respond_to?(:unsafe_load) ? YAML.unsafe_load(yaml_config) : YAML.load(yaml_config)

Sidekiq.configure_server do |config|
  config.redis = { url: cable_array["redis"]["url"] } if Rails.env.development? || Rails.env.test?
  config.redis = { url: cable_array["production"]["url"] } if Rails.env.production?
end

Sidekiq.configure_client do |config|
  config.redis = { url: cable_array["redis"]["url"] } if Rails.env.development? || Rails.env.test?
  config.redis = { url: cable_array["production"]["url"] } if Rails.env.production?
end

if File.exist?(schedule_file) && Sidekiq.server?
  Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file)
end
