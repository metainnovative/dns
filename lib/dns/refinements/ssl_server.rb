module DNS
  module Refinements
    module SSLServer
      refine Async::IO::SSLServer do
        def type
          Socket::SOCK_STREAM
        end
      end
    end
  end
end
