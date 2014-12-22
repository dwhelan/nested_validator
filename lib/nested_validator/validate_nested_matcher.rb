
# RSpec matcher to spec nested validations.
#
# Usage:
#
#     describe Parent do
#       it { should validate_nested(:child) }
#       it { should validate_nested(:child).with_prefix(:thing1) }
#       it { should validate_nested(:child).only(:attribute1) }
#     end

RSpec::Matchers.define :validate_nested do |child_name|

  attr_accessor :parent, :child_name, :child, :prefix, :actual_keys, :only_ones

  CHILD_KEY ||= :key

  match do |parent|
    self.child_name = child_name
    self.child      = parent.send child_name
    self.parent     = parent
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

  #def expected_errors
  #  expected_keys.inject({}){|result, key| result[key] = ['error message'];result }
  #end
  #
  def expected_keys
    child_keys.map{|key| :"#{expected_prefix} #{key}"}
  end

  def child_errors
    child_keys.inject({}){|result, key| result[key] = ['error message'];result }
  end

  def child_keys
    [unique_key, only_ones].flatten.compact
  end

  def unique_key
    CHILD_KEY
  end

  def expected_prefix
    prefix || child_name
  end

  def actual_prefix
    actual_keys.to_s.sub /\s+key$/, ''
  end

  description do
    %Q{validate nested :#{child_name} #{prefix ? "with prefix #{prefix}" : ''}}
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

  chain(:with_prefix) { |prefix| self.prefix = prefix }
  chain(:only)        { |only|   self.only_ones   = Array.wrap(only) }
end
