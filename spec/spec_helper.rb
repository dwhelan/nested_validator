require 'i18n'
require 'rspec/its'
require 'coveralls'


I18n.enforce_available_locales = true
Coveralls.wear!

RSpec.configure do |config|
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  config.alias_it_should_behave_like_to :it_should_validate_nested, 'the parent object should be'
end