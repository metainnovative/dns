max_threads_count = ENV.fetch('RAILS_MAX_THREADS') { 5 }
min_threads_count = ENV.fetch('RAILS_MIN_THREADS') { max_threads_count }
threads min_threads_count, max_threads_count
worker_timeout 3600 if ENV.fetch('RAILS_ENV', 'development') == 'development'
port ENV.fetch('PORT') { 3000 }
environment ENV.fetch('RAILS_ENV') { 'development' }
pidfile ENV.fetch('PIDFILE') { 'tmp/pids/server.pid' }
plugin :tmp_restart

if get(:environment) == 'development'
  require 'rake_tasks/ssl'

  if File.exist?(RakeTasks::SSL::CERT_PATH) && File.exist?(RakeTasks::SSL::KEY_PATH)
    ssl_bind('127.0.0.1', ENV.fetch('SSL_PORT') { 3001 }, cert: RakeTasks::SSL::CERT_PATH, key: RakeTasks::SSL::KEY_PATH)
    ssl_bind('[::1]', ENV.fetch('SSL_PORT') { 3001 }, cert: RakeTasks::SSL::CERT_PATH, key: RakeTasks::SSL::KEY_PATH)
  end
end
