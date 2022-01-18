require 'dns/refinements/resolv_message_decoder'

class Resolv
  class DNS
    class Resource
      module IN
        # Service Binding resource
        class SVCB < Resource
          using ::DNS::Refinements::ResolvMessageDecoder

          TypeValue = 64
          ClassValue = IN::ClassValue
          ClassHash[[TypeValue, ClassValue]] = self # :nodoc:

          def initialize(field_priority, domain_name, field_value = {})
            @field_priority = field_priority
            @domain_name = domain_name
            @field_value = field_value
          end

          ##
          # The priority of this record (relative to
          # others, with lower values preferred). A value of 0 indicates
          # AliasForm.

          attr_reader :field_priority

          ##
          # The domain name of either the alias target (for
          # AliasForm) or the alternative service endpoint (for ServiceForm).

          attr_reader :domain_name

          ##
          # A list of key=value pairs describing
          # the alternative service endpoint for the domain name specified in
          # SvcDomainName (only used in ServiceForm and otherwise ignored).

          attr_reader :field_value

          def encode_rdata(msg) # :nodoc:
            msg.put_pack('n', @field_priority)
            msg.put_name(@domain_name)

            @field_value.each do |param_key, param_value|
              msg.put_pack('nn', param_key, param_value.bytesize)
              msg.put_bytes(param_value)
            end if @field_priority > 0
          end

          def self.decode_rdata(msg) # :nodoc:
            field_priority, = msg.get_unpack('n')
            domain_name = msg.get_name
            field_value = field_priority > 0 ? msg.get_pairs_list : {}

            return self.new(field_priority, domain_name, field_value)
          end
        end

        # HTTPS Binding resource
        class HTTPS < SVCB
          TypeValue = 65
          ClassHash[[TypeValue, ClassValue]] = self # :nodoc:
        end
      end
    end
  end
end
