module Authentication
  module AuthnJwt
    # Factory that receives a vendor name and returns the appropriate JWT vendor configuration class
    class JwtConfigurationFactory
      VENDORS = {
        "dummy" => JWTConfigurationDummyVendor
      }

      def create_jwt_configuration(vendor)
        VENDORS[vendor] || raise("Vendor #{vendor} not implemented yet.")
      end
    end
  end
end
