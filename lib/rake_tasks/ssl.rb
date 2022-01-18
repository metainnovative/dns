require 'openssl/pkey/rsa'
require 'resolv'

module RakeTasks
  module SSL
    HOST = 'dns.metainnovative.net'.freeze
    DIR_PATH = Rails.root.join('config', 'ssl')
    KEY_PATH = DIR_PATH.join("#{HOST}.key")
    CERT_PATH = DIR_PATH.join("#{HOST}.crt")

    module_function

    def ca_cert # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      root_key = OpenSSL::PKey::RSA.new(4096)
      root_ca = OpenSSL::X509::Certificate.new
      root_ca.version = 2
      root_ca.serial = 1
      root_ca.subject = OpenSSL::X509::Name.parse('/C=FR/O=MetaInnovative/CN=MetaInnovative CA')
      root_ca.issuer = root_ca.subject
      root_ca.public_key = root_key.public_key
      root_ca.not_before = Time.current
      root_ca.not_after = root_ca.not_before.next_year(30)
      ef = OpenSSL::X509::ExtensionFactory.new
      ef.subject_certificate = root_ca
      ef.issuer_certificate = root_ca
      root_ca.add_extension(ef.create_extension('basicConstraints', 'CA:TRUE', true))
      root_ca.add_extension(ef.create_extension('keyUsage', 'keyCertSign, cRLSign', true))
      root_ca.add_extension(ef.create_extension('subjectKeyIdentifier', 'hash', false))
      root_ca.add_extension(ef.create_extension('authorityKeyIdentifier', 'keyid:always, issuer:always', false))
      root_ca.sign(root_key, OpenSSL::Digest::SHA512.new)

      [root_key, root_ca]
    end

    def cert(cn:, subject_alt_names: []) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Naming/MethodParameterName
      root_key, root_ca = ca_cert

      key = OpenSSL::PKey::RSA.new(4096)
      cert = OpenSSL::X509::Certificate.new
      cert.version = 2
      cert.serial = 2
      cert.subject = OpenSSL::X509::Name.parse("/C=FR/O=MetaInnovative/CN=#{cn}")
      cert.issuer = root_ca.subject
      cert.public_key = key.public_key
      cert.not_before = Time.current
      cert.not_after = cert.not_before.next_year
      ef = OpenSSL::X509::ExtensionFactory.new
      ef.subject_certificate = cert
      ef.issuer_certificate = root_ca
      cert.add_extension(ef.create_extension('basicConstraints', 'CA:FALSE', true))
      cert.add_extension(ef.create_extension('keyUsage', 'nonRepudiation, digitalSignature, keyEncipherment, dataEncipherment', true))
      cert.add_extension(ef.create_extension('extendedKeyUsage', 'serverAuth, clientAuth', false))
      cert.add_extension(ef.create_extension('subjectKeyIdentifier', 'hash', false))
      cert.add_extension(ef.create_extension('authorityKeyIdentifier', 'keyid:always', false))

      if subject_alt_names.any?
        subject_alt_names = subject_alt_names.map do |subject_alt_name|
          case subject_alt_name
          when Resolv::IPv4::Regex, Resolv::IPv6::Regex
            "IP:#{subject_alt_name}"
          else
            "DNS:#{subject_alt_name}"
          end
        end.join(',')

        cert.add_extension ef.create_extension('subjectAltName', subject_alt_names)
      end

      cert.sign(root_key, OpenSSL::Digest::SHA512.new)

      [key, cert, root_ca]
    end
  end
end
