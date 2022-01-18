require 'rake_tasks/ssl'

namespace :server do
  namespace :ssl do
    desc 'Generate ssl'
    task generate: :environment do
      key, cert, root_ca = RakeTasks::SSL.cert(cn: 'dns.metainnovative.local', subject_alt_names: %w[dns.metainnovative.local])

      FileUtils.mkdir_p(RakeTasks::SSL::DIR_PATH)

      File.write(RakeTasks::SSL::KEY_PATH, key.to_pem_pkcs8)
      File.write(RakeTasks::SSL::CERT_PATH, "#{root_ca}#{cert.to_pem}")
    end
  end
end
