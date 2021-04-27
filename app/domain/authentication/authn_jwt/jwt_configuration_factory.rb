module Authentication
  module AuthnJwt
    # Factory that receives vendor name and returns appropriate JWT vendor configuration class
    class JwtConfigurationFactory
      VENDORS = {
        "dummy" => JWTConfigurationDummyVendor
      }

      def get_jwt_configuration(vendor)
        unless VENDORS.key?(vendor)
          raise "Vendor #{vendor} not implemented yet."
        end
        (VENDORS[vendor]).new
      end
    end
  end
end
