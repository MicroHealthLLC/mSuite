threads_count = ENV.fetch("RAILS_MAX_THREADS") { 15 }.to_i
        threads threads_count, threads_count
        bind "unix:/var/www/mindmap/tmp/rails.sock"
        environment ENV.fetch("RAILS_ENV") { "production" }
        workers ENV.fetch("WEB_CONCURRENCY") { 6 }
        daemonize true
        pidfile '/var/www/mindmap/tmp/pids/puma.pid'
