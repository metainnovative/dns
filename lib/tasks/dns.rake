require 'dns/server'

namespace :dns do
  desc 'DNS Server'
  task server: :environment do
    DNS::Server.start(
      tls: true,
      tls_cert: Rails.root.join('config', 'ssl', 'dns.metainnovative.net.crt'),
      tls_key: Rails.root.join('config', 'ssl', 'dns.metainnovative.net.key')
    )
  end
end
