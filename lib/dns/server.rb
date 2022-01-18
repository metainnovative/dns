require 'dns/refinements/resolv_message'
require 'dns/rule_based_server'
require 'openssl/ssl'

module DNS
  module Server
    using DNS::Refinements::ResolvMessage

    UPSTREAM = RubyDNS::Resolver.new([[:ssl, '8.8.8.8', 853], [:ssl, '8.8.4.4', 853], [:ssl, '1.1.1.1', 853], [:ssl, '1.0.0.1', 853]])
    IN = Resolv::DNS::Resource::IN

    DEFAULT_ADDRESS = '0.0.0.0'
    DEFAULT_ADDRESS6 = '::'

    module_function

    def blocked?(transaction, logger)
      remote_address = transaction.options[:remote_address]
      client = Client.find_or_create_by(ip_address: remote_address.ip_address)
      name = transaction.question.to_s

      return false if Cache.client(client).permit.find_by(value: name)
      return true if Cache.client(client).block.find_by(value: name)

      false
    rescue StandardError => e
      logger.error "<#{transaction.query.id}> #{e.message}"

      false
    end

    def blocked_logger(transaction, logger)
      remote_address = transaction.options[:remote_address]

      logger.info "<#{transaction.query.id}> Blocked request #{transaction.name} from #{remote_address.inspect_sockaddr}."
    end

    def question_logger(transaction, duration, logger)
      remote_address = transaction.options[:remote_address]
      request_proto = case remote_address.socktype
                      when Socket::SOCK_STREAM
                        'TCP'
                      when Socket::SOCK_DGRAM
                        'UDP'
                      else
                        'UNKNOWN'
                      end
      response_flags = []
      response_flags << 'qr' if transaction.response.qr == 1
      response_flags << 'aa' if transaction.response.aa == 1
      response_flags << 'tc' if transaction.response.tc == 1
      response_flags << 'rd' if transaction.response.rd == 1
      response_flags << 'ra' if transaction.response.ra == 1

      logger.info "<#{transaction.query.id}> #{remote_address.inspect_sockaddr} " +
                    "\"#{transaction.resource_class.name.demodulize} IN #{transaction.name}. #{request_proto} #{transaction.query.encode.size}\" " +
                    "#{transaction.response.rname} #{response_flags.join(',')} #{transaction.response.encode.size} #{duration}s"
    rescue StandardError => e
      logger.error "<#{transaction.query.id}> #{e.message}"
    end

    def start(options = {})
      enable_tcp = options.fetch(:tcp, true)
      enable_udp = options.fetch(:udp, true)
      enable_tls = options.fetch(:tls, false)
      port = options.fetch(:port, 53)
      tls_port = options.fetch(:tls_port, 853)
      enable_ip6 = options.fetch(:ip6, true)
      tls_cert = options[:tls_cert]
      tls_key = options[:tls_key]
      interfaces = []

      if enable_tcp
        interfaces << [:tcp, DEFAULT_ADDRESS, port]
        interfaces << [:tcp, DEFAULT_ADDRESS6, port] if enable_ip6
      end

      if enable_udp
        interfaces << [:udp, DEFAULT_ADDRESS, port]
        interfaces << [:udp, DEFAULT_ADDRESS6, port] if enable_ip6
      end

      if enable_tls && tls_cert && tls_key
        ssl_context = OpenSSL::SSL::SSLContext.new
        ssl_context.cert = OpenSSL::X509::Certificate.new(File.read(tls_cert))
        ssl_context.key = OpenSSL::PKey::RSA.new(File.read(tls_key))

        interfaces << Async::IO::Endpoint.ssl(DEFAULT_ADDRESS, tls_port, ssl_context: ssl_context)
        interfaces << Async::IO::Endpoint.ssl(DEFAULT_ADDRESS6, tls_port, ssl_context: ssl_context) if enable_ip6
      end

      RubyDNS::run_server(interfaces, server_class: DNS::RuleBasedServer) do
        match(->(transaction) { DNS::Server.blocked?(transaction, logger) }, [IN::A, IN::AAAA]) do |transaction|
          DNS::Server.blocked_logger(transaction, logger)

          if transaction.resource_class == IN::A
            transaction.respond!('127.0.0.1')
          elsif transaction.resource_class == IN::AAAA
            transaction.respond!('::1')
          end
        end

        question_logger do |transaction, duration|
          DNS::Server.question_logger(transaction, duration, logger)
        end

        otherwise do |transaction|
          transaction.passthrough!(UPSTREAM)
        rescue StandardError => e
          logger.error "<#{transaction.query.id}> #{e.message}"

          transaction.fail!(Resolv::DNS::RCode::ServFail)
        end
      end
    end
  end
end