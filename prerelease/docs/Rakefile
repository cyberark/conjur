
desc "Generate documentation files for the policy"
task :"policy-doc" do
  require 'conjur-policy-parser'

  require 'conjur/policy/doc'
  require 'fileutils'
  require 'active_support'
  require 'active_support/core_ext'
  
  FileUtils.rm_rf '_data/policy'
  FileUtils.mkdir_p '_data/policy'
  
  Conjur::Policy::Doc.list.each do |item|
    document = item.to_h
    if document[:attributes] && !document[:attributes].empty?
      document[:attributes] = document[:attributes].select do |attr|
        !%w(account annotations id owner).member?(attr.id)
      end.map(&:to_h).map(&:stringify_keys)
    end
    
    document.delete(:attributes) if document[:attributes].blank?
    document.delete(:attributes_description) if document[:attributes_description].blank?
    document.delete(:privileges_description) if document[:privileges_description].blank?

    document = document.stringify_keys
    File.write File.join('_data/policy', "#{item.id.underscore}.yml"), document.to_yaml
  end
end

desc "Generate cucumber YARD doc"
task :"cuke-doc" do |t,args|
  require 'docker-api'

  image = Dir.chdir('yard-cucumber') { Docker::Image.build_from_dir '.' }
  container = Docker::Container.create('Cmd' => [], 
    'Image' => image.id, 
    'HostConfig' => { 'Binds' => [ "#{Dir.pwd}/yard-cucumber:/mnt/doc" ] })
  begin
    container.start
    result = container.wait
    $stderr.puts container.logs(stdout: true, stderr: true)
    status = result['StatusCode']
    raise "cucumber-yard failed: #{status}" unless status == 0
  ensure
    container.delete(:force => true)
  end
end
