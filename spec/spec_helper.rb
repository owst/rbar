require 'rbar'

Bundler.require(:development)

RSpec.configure do |config|
  config.example_status_persistence_file_path = 'spec_examples.txt'
end
