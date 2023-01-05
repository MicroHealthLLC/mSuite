require 'yaml'

if File.exist?("./puma_config.yml")
  yaml_data = YAML.load_file('./puma_config.yml')
  yaml_data.each do |key, value|
    next if !value
    ENV[key] = value
  end
end
rails_env = ENV.fetch('RAILS_ENV')
puma_port = Integer(ENV.fetch('PUMA_PORT'))
max_threads_count = ENV.fetch('RAILS_MAX_THREADS', 5)
min_threads_count = ENV.fetch('RAILS_MIN_THREADS', max_threads_count)
workers Integer(ENV.fetch('WEB_CONCURRENCY', 2))
threads min_threads_count, max_threads_count
#nakayoshi_fork
wait_for_less_busy_worker
fork_worker
environment rails_env
if rails_env == 'production'
  pidfile ENV.fetch('PUMA_PIDFILE')
  ssl_bind(
    ENV.fetch('PUMA_SSL_HOST'),
    puma_port,
    key: ENV.fetch('PUMA_SSL_KEY_FILE'),
    cert: ENV.fetch('PUMA_SSL_CERT_FILE'),
    verify_mode: ENV.fetch('PUMA_SSL_VERIFY_MODE')
  )
else
port puma_port
end
plugin :tmp_restart
preload_app!
