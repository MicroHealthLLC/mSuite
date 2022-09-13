require 'yaml'

schedule_file = 'config/schedule.yml'
cable_array = YAML.load(File.read("config/cable.yml"))

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
