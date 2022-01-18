require 'dns/refinements/in'
require 'dns/refinements/resolv_message'
require 'dns/refinements/ssl_server'
require 'dns/refinements/transaction'

class Async::IO::SSLServer
  def type
    Socket::SOCK_STREAM
  end
end

module DNS
  class RuleBasedServer < RubyDNS::RuleBasedServer
    using Refinements::ResolvMessage
    using Refinements::SSLServer
    using Refinements::Transaction

    class Rule < RubyDNS::RuleBasedServer::Rule
      def call(server, name, resource_class, transaction)
        unless match(name, resource_class)
          server.logger.debug "<#{transaction.query.id}> Resource class #{resource_class} failed to match #{@pattern[1].inspect}!"

          return false
        end

        if (@pattern[0].call(transaction) rescue false)
          server.logger.debug "<#{transaction.query.id}> Callable pattern matched."

          @callback[transaction]

          return true
        else
          server.logger.debug "<#{transaction.query.id}> No pattern matched."

          return false
        end
      end
    end

    def match(*pattern, &block)
      @rules << Rule.new(pattern, block)
    end

    def question_logger(&block)
      @question_logger = block
    end

    def process(name, resource_class, transaction)
      start_time = Time.now

      super

      end_time = Time.now

      @question_logger.call(transaction, end_time - start_time) if @question_logger
    end
  end
end
