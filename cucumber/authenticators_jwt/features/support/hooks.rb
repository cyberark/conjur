# frozen_string_literal: true

# clean "local" JWKS state
After do
  clean_local_state
end

# clean "remote" JWKS state
After do
  clean_remote_state
end
