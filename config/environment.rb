# Load the Rails application.
require_relative 'application'

settings_file = File.join(Rails.root, 'config', 'settings.yml')
if File.exist?(settings_file)
  YAML.safe_load(File.open(settings_file)).each do |k, v|
    ENV[k.to_s] = v
  end
end

# Initialize the Rails application.
Rails.application.initialize!
