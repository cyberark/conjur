ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' # Set up gems listed in the Gemfile.

# in circumstances unexplained sometimes this ends up not in the load path
$: << File.expand_path('../../lib', __FILE__)
