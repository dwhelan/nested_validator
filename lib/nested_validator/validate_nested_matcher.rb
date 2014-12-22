
# RSpec matcher to spec nested validations.
#
# You can use symbols or strings for any values.
#
# Usage:
#
#     describe Parent do
#       it { should validate_nested(:child) }
#       it { should validate_nested(:child).with_prefix(:thing1) }
#       it { should validate_nested(:child).only(:attribute1) }
#       it { should validate_nested(:child).only(:attribute1, :attribute2) }
#     end

RSpec::Matchers.define :validate_nested do |child_name|

  attr_accessor :parent, :child_name, :child, :prefix, :actual_keys, :only_keys

  match do |parent|
    self.child_name  = child_name
    self.child       = parent.send child_name
    self.parent      = parent
    self.actual_keys = (invalid_error_keys - valid_error_keys)

    #binding.pry
    actual_keys == expected_keys
  end

  def valid_error_keys
    allow(child).to receive(:valid?) { true }
    error_keys
  end

  def invalid_error_keys
    allow(child).to receive(:valid?) { false }
    error_keys
  end

  def error_keys
    allow(child).to receive(:errors) { child_errors }
    parent.valid?
    parent.errors.keys
  end

  def expected_keys
    expected_child_keys.map{|key| :"#{expected_prefix} #{key}"}
  end

  def expected_child_keys
    keyify only_keys ? only_keys : child_keys
  end

  def child_errors
    child_keys.inject({}){|result, key| result[key] = ['error message'];result }
  end

  TEST_KEY ||= :__unique_key__

  def child_keys
    keyify TEST_KEY, only_keys
  end

  def keyify(*keys)
    keys.flatten.compact
  end

  def expected_prefix
    prefix || child_name
  end

  def actual_prefix
    actual_keys.first.to_s.sub /\s+#{TEST_KEY}$/, ''
  end

  description do
    message = "validate nested :#{child_name}"
    message << " with only #{only_keys.join(', ')}" if only_keys
    message << " with prefix #{prefix}" if prefix
    message
  end

  failure_message do |parent|
    if actual_keys
      hint = prefix ? '' : " - perhaps add .with_prefix('#{actual_prefix}')"
      "#{parent} was validated but the error prefix was '#{actual_prefix}' rather than '#{expected_prefix}'#{hint}'"
    else
      "expected #{parent} to validate nested attribute :#{child_name}"
    end
  end

  failure_message_when_negated do |parent|
    "expected #{parent} not to validate nested attribute :#{child_name}"
  end

  chain(:with_prefix) { |prefix| self.prefix    = prefix.to_s }
  chain(:only)        { |*only|  self.only_keys = only }
end
