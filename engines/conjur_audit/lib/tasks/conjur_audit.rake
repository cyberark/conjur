# frozen_string_literal: true

namespace :railties do
  namespace :install do
    desc 'Copy engine migration files into wrapper migrate directory'
    task migrations: :environment do
      source = File.expand_path('../../db/migrate', __dir__)
      destination = File.expand_path('../../../../db/migrate', __dir__)
      raise "Directory #{source} does not exist. Must supply a valid source migration path" unless File.directory?(source)
      raise "Directory #{destination} does not exist. Must supply a valid destination migration path" unless File.directory?(destination)
      MigrationTask.copy_migrations destination, source
    end
  end
end

module MigrationTask
  class << self
    MIGRATION_FILE_PATTERN = /\A(\d+)_.+\.rb\z/i
    MIGRATION_FILENAME_REGEXP = /\A([0-9]+)_([_a-z0-9]*)\.?([_a-z0-9]*)?\.rb\z/

    def copy_migrations(destination, source)
      scope = "conjur_audit"
      version = file_version
      destination_migrations = migrations(destination)
      source_migrations = migrations(source)
      source_migrations.each do |migration|
        if destination_migrations.detect { |m| m.name == migration.name}
          next
        end
        new_path = File.join(destination, "#{version}_#{migration.name}.#{scope}.rb")
        FileUtils.cp(migration.filename, new_path)
        version += 1
      end
    end

    private

    def migrations(migrations_paths)
      migrations = migration_files(migrations_paths).map do |m_file|
        version, name = parse_migration_filename(m_file)
        raise "Illegal name for migration file #{m_file}" unless version
        version = version.to_i
        Struct.new(:name, :version, :filename).new(name, version, m_file)
      end
      migrations.sort_by(&:version)
    end

    def migration_files(migrations_paths)
      paths = Array([migrations_paths])
      Dir[*paths.flat_map { |path| "#{path}/**/[0-9]*_*.rb" }]
    end

    def parse_migration_filename(filename)
      File.basename(filename).scan(MIGRATION_FILENAME_REGEXP).first
    end

    def file_version
      20_190_924_122_146
    end
  end
end
