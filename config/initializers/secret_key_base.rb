# frozen_string_literal: true

require 'securerandom'

Rails.application.config.secret_key_base = SecureRandom.hex(64)
