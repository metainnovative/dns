module OpenSSL
  module PKey
    class RSA
      def to_der_pkcs8
        return to_der unless private?

        OpenSSL::ASN1::Sequence([
                                  OpenSSL::ASN1::Integer(0),
                                  OpenSSL::ASN1::Sequence([OpenSSL::ASN1::ObjectId('rsaEncryption'), OpenSSL::ASN1::Null.new(nil)]),
                                  OpenSSL::ASN1::OctetString(to_der)
                                ]).to_der
      end

      def to_pem_pkcs8
        return to_pem unless private?

        "-----BEGIN PRIVATE KEY-----\n#{Base64.strict_encode64(to_der_pkcs8).chars.each_slice(64).map(&:join).join("\n")}\n-----END PRIVATE KEY-----\n"
      end
    end
  end
end
