# frozen_string_literal: true

require 'fileutils'
require 'time'
require 'pathname'

desc "Export the Conjur data necessary to migrate to Enterprise Edition"
task :export, [ "out_dir" ] do |t,args|
  out_dir = Pathname.new args[:out_dir]

  puts "Exporting to '#{out_dir}'..."

  # Make sure output directory exists and we can write to it
  FileUtils.mkpath out_dir
  FileUtils.chmod 0770, out_dir

  export_key_file = out_dir.join("key")
  if File.exist?(export_key_file)
    puts "Using key from #{export_key_file}"
  else
    generate_key(export_key_file)
  end

  # Timestamp to name export file
  timestamp = Time.now.strftime("%Y-%m-%dT%H-%M-%SZ")

  dbdump = data_key_file = archive_file = nil
  with_umask 077 do
    # Export Conjur database
    FileUtils.mkpath out_dir.join("backup")
    dbdump = out_dir.join("backup/conjur.db")
    call %(pg_dump -Fc -f \"#{dbdump}\" #{ENV['DATABASE_URL']}) or
      raise 'unable to get database backup'

    # export CONJUR_DATA_KEY
    FileUtils.mkpath out_dir.join("etc")
    data_key_file = out_dir.join("etc/possum.key")
    File.write(data_key_file, "CONJUR_DATA_KEY=#{ENV['CONJUR_DATA_KEY']}\n")

    archive_file = out_dir.join("#{timestamp}.tar.xz")
    call %(tar Jcf "#{archive_file}" -C "#{out_dir}" ) +
         %(--transform="s|^|/opt/conjur/|" ) +
         %("#{dbdump.relative_path_from(out_dir)}" "#{data_key_file.relative_path_from(out_dir)}") or
      raise 'unable to make archive for backup'
  end

  call %(gpg -c --cipher-algo AES256 --batch --passphrase-file ) +
    %("#{export_key_file}" --no-use-agent "#{archive_file}")

  puts
  puts "Export placed in #{archive_file}.gpg"
  puts "It's encrypted with key in #{export_key_file}."
  puts "If you're going to store the export, make"
  puts "sure to store the key file separately."

ensure
  call %(rm -f "#{archive_file}" "#{dbdump}" "#{data_key_file}") or
  warn 'unable to remove temporary files'
end

def with_umask umask, &block
  saved_umask = File.umask umask
  begin
    yield
  ensure
    File.umask saved_umask
  end
end

def call *args
  system(*args).tap do |result|
    warn "command #{Array(args).join(' ')} failed" unless result
  end
end

def generate_key(file)
  with_umask 077 do
    puts "Generating key file #{file}"
    File.write(file, SecureRandom.base64(64))
  end
end
