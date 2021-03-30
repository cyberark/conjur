# frozen_string_literal: true

# Monkey patch to use migrations from the engine
def (SequelRails::Migrations).migrations_dir
  File.expand_path('../../../../../db/migrate', __FILE__)
end
