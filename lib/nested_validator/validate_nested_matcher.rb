# RSpec matcher to spec nested validations.
#
# Usage:
#
#     describe Parent do
#       it { should validate_nested(:child) }
#     end

RSpec::Matchers.define :validate_nested do |child_name|
  match do |parent|
    @child_name = child_name
    child = parent.send child_name

    allow(child).to receive(:valid?) { false }
    allow(child).to receive(:errors) { { key: 'error message' } }
    parent.valid?
    parent.errors.include? :"#{child_name} key"
  end

  #description do
  #  "delegate :#{@method} to its #{@to}#{@prefix ? ' with prefix' : ''}"
  #end
  #
  failure_message do |text|
    "expected #{text} to validate nested attribute :#{@child_name}"
  end

  failure_message_when_negated do |text|
    "expected #{text} not to validate nested attribute :#{@child_name}"
  end
  #
  #chain(:to) { |receiver| @to = receiver }
  #chain(:with_prefix) { |prefix| @prefix = prefix || @to }
  #
  def invalid_child_double(child)
    double(child, :'valid?' => false, errors: { key: 'error message'} )
  end
end
