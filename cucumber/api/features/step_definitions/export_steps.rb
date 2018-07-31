When(/^I run conjurctl export$/) do
  system("conjurctl export -o cuke_export/") || fail('Could not execute `conjurctl export`')
end

Then(/^the export file exists$/) do
  Dir['cuke_export/*.tar.xz.gpg'].any? || fail('No export archive file exists')
  File.exists?('cuke_export/key') || fail('No export archive key file exists')
end

Then (/^the accounts file contains "([^"]*)"$/) do |contents|
  key_file = 'cuke_export/key'.freeze
  temp_dir = "#{Dir.tmpdir()}/#{SecureRandom.hex(5)}".freeze
  plain_backup_file = temp_dir + '/backup.tar.xz'
  backup_file = Dir['cuke_export/*.tar.xz.gpg'].sort().first

  # Decrypt export archive
  FileUtils.mkpath(temp_dir)
  system %(gpg --quiet --batch --no-use-agent --passphrase-file #{key_file} -o #{plain_backup_file} #{backup_file})
  
  Dir.chdir temp_dir do
    # Extract archive contents
    system %(tar -v -x -f #{plain_backup_file})

    # Check accounts contents
    accounts = File.read("#{temp_dir}/opt/conjur/backup/accounts")
    fail('Exported accounts does not contain expected content') unless accounts.include?(contents)
  end 
ensure
  FileUtils.rm_rf(temp_dir)
end