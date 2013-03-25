require 'bundler/setup'
Bundler.require(:default, :development, :test)

VCR.configure do |config|
  config.cassette_library_dir = 'spec/files/requests'
  config.hook_into :webmock
  config.configure_rspec_metadata!
end

RSpec.configure do |config|
  config.mock_with :rspec

  # so we can use :vcr rather than :vcr => true;
  # in RSpec 3 this will no longer be necessary.
  config.treat_symbols_as_metadata_keys_with_true_values = true
end
