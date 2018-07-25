When(/^I run conjurctl export$/) do
  system("conjurctl export -o cuke_export/") || fail
end

Then(/^the export file exists$/) do
  Dir['cuke_export/*.tar.xz.gpg'].any? || fail
  File.exists?('cuke_export/key') || fail
end
