# frozen_string_literal: true

require 'fileutils'
require 'time'
require 'pathname'

desc 'Export the Conjur data necessary to migrate to Enterprise Edition'
task :export, %w[out_dir label] => :environment do |_t, args|
  out_dir = Pathname.new(args[:out_dir])
  label = args[:label]

  puts("Exporting to '#{out_dir}'...")
  ExportTask.create_export_directory(out_dir)
  export_key_file = ExportTask.ensure_export_key(out_dir)  

  archive_file = nil
  files = []
  ExportTask.with_umask(077) do
    files.push(ExportTask.export_database(out_dir))
    files.push(ExportTask.export_data_key(out_dir))
    files.push(ExportTask.export_accounts(out_dir))
    archive_file = ExportTask.create_export_archive(out_dir, label, files)    
  end

  ExportTask.encrypt_export_archive(export_key_file, archive_file)
  
  puts
  puts("Export placed in #{archive_file}.gpg")
  puts("It's encrypted with key in #{export_key_file}.")
  puts("If you're going to store the export, make")
  puts('sure to store the key file separately.')

ensure
  ExportTask.cleanup_export_files(archive_file, out_dir)  
end

module ExportTask
  class << self
    def create_export_directory(out_dir)
      # Make sure output directory exists and we can write to it
      FileUtils.mkpath(out_dir)
      FileUtils.chmod(0770, out_dir)
    end

    def ensure_export_key(out_dir)
      export_key_file = out_dir.join('key')
      if File.exist?(export_key_file)
        puts("Using key from #{export_key_file}")
      else
        generate_key(export_key_file)
      end
      export_key_file
    end

    def export_database(out_dir) 
      # Export Conjur database
      FileUtils.mkpath(out_dir.join('backup'))
      dbdump = out_dir.join('backup/conjur.db')
      call(%(pg_dump -Fc -f \"#{dbdump}\" #{ENV['DATABASE_URL']})) ||
        raise('unable to get database backup')
      dbdump
    end

    def export_data_key(out_dir)
      # export CONJUR_DATA_KEY
      FileUtils.mkpath(out_dir.join('etc'))
      data_key_file = out_dir.join('etc/possum.key')
      File.write(data_key_file, "CONJUR_DATA_KEY=#{ENV['CONJUR_DATA_KEY']}\n")
      data_key_file
    end

    def export_accounts(out_dir)
      FileUtils.mkpath(out_dir.join('backup'))
      accounts_file = out_dir.join('backup/accounts')

      # Select all accounts from database, ordered by
      # the number of resources in that account
      accounts =  Sequel::Model.db.fetch(%{
                      Select account from (
                      SELECT account(resource_id) as account FROM resources
                      UNION
                      SELECT account(role_id) as account FROM roles
                      ) as accounts
                      WHERE account != '!'
                      GROUP BY account                
                      ORDER BY count(*);
                    })
                    .map {|row| row[:account]}
                    .join("\n")
      File.write(accounts_file, accounts)
      accounts_file
    end

    def create_export_archive(out_dir, label, files)
      archive_file = out_dir.join("#{label}.tar.xz")
      call(%(tar Jcf "#{archive_file}" -C "#{out_dir}" ) +
          %(--transform="s|^|/opt/conjur/|" ) +
          relative_paths(files, out_dir)) ||
        raise('unable to make archive for backup')
      archive_file
    end

    def relative_paths(files, relative_from)
      files.map { |file| %("#{file.relative_path_from(relative_from)}") }
           .join(' ')
    end

    def encrypt_export_archive(export_key_file, archive_file)
      call(%(gpg -c --cipher-algo AES256 --batch --passphrase-file ) +
          %("#{export_key_file}" --no-use-agent "#{archive_file}"))
    end

    def cleanup_export_files(archive_file, out_dir)
      call(%(rm -rf "#{archive_file}" "#{out_dir.join('backup')}" "#{out_dir.join('etc')}")) ||
        warn('unable to remove temporary files')
    end

    def call(*args)
      system(*args).tap do |result|
        warn("command #{Array(args).join(' ')} failed") unless result
      end
    end

    def generate_key(file)
      with_umask(077) do
        puts("Generating key file #{file}")
        File.write(file, SecureRandom.base64(64))
      end
    end

    def with_umask(umask)
      saved_umask = File.umask(umask)
      begin
        yield
      ensure
        File.umask(saved_umask)
      end
    end
  end
end
