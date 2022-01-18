module DNS
  module Refinements
    module ResolvMessageDecoder
      refine Resolv::DNS::Message::MessageDecoder do
        def get_pairs_list
          pairs = {}
          while @index < @limit
            key, len = self.get_unpack('nn')
            pairs[key] = self.get_bytes(len)
          end
          pairs
        end
      end
    end
  end
end
