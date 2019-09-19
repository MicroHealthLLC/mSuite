threads_count = ENV.fetch("RAILS_MAX_THREADS") { 15 }.to_i
threads threads_count, threads_count
bind "unix:/home/bilel/Desktop/rails_projects/mindmap/tmp/bluebird2.sock"
environment ENV.fetch("RAILS_ENV") { "production" }
workers ENV.fetch("WEB_CONCURRENCY") { 6 }
daemonize false
pidfile '/home/bilel/Desktop/rails_projects/mindmap/tmp/pids/puma.pid'