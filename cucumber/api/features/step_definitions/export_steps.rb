When(/^I run conjurctl export(?: with label "([^"]*)")?$/) do |label|
  command = 'conjurctl export -o /tmp/cuke_export/'
  command << " -l #{label}" unless label.nil?
  system(command) || fail('Could not execute `conjurctl export`')
end

Then(/^the export file exists(?: with label "([^"]*)")?$/) do |label|
  archive_name = label.nil? ? '*' : label
  Dir["/tmp/cuke_export/#{archive_name}.tar.xz.gpg"].any? || fail('No export archive file exists')
  File.exist?('/tmp/cuke_export/key') || fail('No export archive key file exists')
end

Then (/^the accounts file contains "([^"]*)"$/) do |contents|
  key_file = '/tmp/cuke_export/key'.freeze
  backup_file = Dir['/tmp/cuke_export/*.tar.xz.gpg'].min()

  Dir.mktmpdir do |temp_dir|
    plain_backup_file = "#{temp_dir}/backup.tar.xz"

    # Decrypt export archive
    system %(gpg --quiet --batch --no-use-agent --passphrase-file #{key_file} -o #{plain_backup_file} #{backup_file})

    Dir.chdir(temp_dir) do
      # Extract archive contents
      system %(tar -v -x -f #{plain_backup_file})
  
      # Check accounts contents
      accounts = File.read("#{temp_dir}/opt/conjur/backup/accounts")
      fail('Exported accounts does not contain expected content') unless accounts.include?(contents)
    end 
  end
end
