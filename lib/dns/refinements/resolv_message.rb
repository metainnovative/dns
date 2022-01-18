module Resolv::DNS::RCode
  TO_NAME = Resolv::DNS::RCode.constants.map { |name| [Resolv::DNS::RCode.const_get(name), name.upcase.freeze] }.to_h.freeze
end

module DNS
  module Refinements
    module ResolvMessage
      refine Resolv::DNS::Message do
        def rname
          Resolv::DNS::RCode::TO_NAME[rcode]
        end
      end
    end
  end
end
