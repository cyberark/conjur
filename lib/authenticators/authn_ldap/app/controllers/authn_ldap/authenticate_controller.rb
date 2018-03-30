require_dependency 'authn_ldap/application_controller'

module AuthnLdap
  class AuthenticateController < ApplicationController
    def authenticate
      render json: {
        protected: "eyJhbGciOiJjb25qdXIub3JnL3Nsb3NpbG8vdjIiLCJraWQiOiI0NGIwMjBmNjY0MDBmNzFhZDQ3Y2I0N2IzYTFiNmU5MSJ9",
        payload: "eyJzdWIiOiJhbGljZSIsImlhdCI6MTUwNTgzMDY1MX0=",
        signature: "iRLTwNomb_b6TS4e539IIC-isPsc0kIn-F_ajlvnGdrN6brEEHnVha2vm0oDwOjpnmpFrMYLzn8aPo4_7DP3edssfQbpMG6OZI2Ea9DRfkhQGtSQ2fQvhDos_f16EX_jWQkYlsY6T_RurAxf_7VC4hEhjZA8nLkXOohA1DheyoJiT2-7vdpLmf42G7r1gPWHd_JuFkee28Ax2vCi35l4yQXkAHFaLkb3cAD2iwYuavv3qcFnYsT5WhLQqndPoNzgNa4dMvWRkVNUoVmvL30oE6lAlWPO4rFbPpmLwJRJFudDF8IVV9cVRKnV3z79_3RfEsHJ6YTHVX4Cv--cXmkT17QSFp87DK94DAOX3jKvJNo49DdqkzXqAPUIj3CD3IWI"
      }
    end
  end
end
