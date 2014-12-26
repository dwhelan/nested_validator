require 'rspec/expectations'

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
#       it { should validate_nested(:child).except(:attribute1) }
#     end
RSpec::Matchers.define :validate_nested do |child_name|

  attr_accessor :child_name, :prefix, :only_keys, :except_keys # inputs
  attr_accessor :parent, :actual_keys

  TEST_KEY ||= :__test_key__

  match do |parent|
    self.prefix      ||= ''
    self.only_keys   ||= []
    self.except_keys ||= []

    self.child_name  = child_name
    self.parent      = parent

    return false unless parent.respond_to? child_name
    self.actual_keys = (error_keys_when_child_validity_is(false) - error_keys_when_child_validity_is(true))
    return false if invalid_child_keys.present?


    actual_keys == expected_keys
  end

  chain(:with_prefix) { |prefix|  self.prefix      = prefix }
  chain(:only)        { |*only|   self.only_keys   = only   }
  chain(:except)      { |*except| self.except_keys = except }

  def child
    parent.send child_name
  end

  def error_keys_when_child_validity_is(valid)
    child_error_keys = combine TEST_KEY, only_keys, except_keys
    child_errors = child_error_keys.inject({}){|result, key| result[key] = ['error message'];result }

    allow(child).to receive(:valid?) { valid }
    allow(child).to receive(:errors) { valid ? [] : child_errors }

    parent.valid?
    parent.errors.keys
  end

  def expected_keys
    expected_child_keys.map{|key| :"#{expected_prefix} #{key}"}
  end

  def expected_prefix
    prefix.present? ? prefix : child_name
  end

  def actual_prefix
    :"#{actual_keys.first.to_s.split.first}"
  end

  def expected_child_keys
    expected_keys = only_keys.present? ? only_keys : [TEST_KEY]
    unique_except_keys = except_keys - only_keys
    combine expected_keys - unique_except_keys
  end

  def actual_child_keys
    actual_keys.map{|key| key.to_s.sub(/^.*\s+/, '').to_sym }
  end

  def invalid_child_keys
    (only_keys + except_keys).reject{|key| child.respond_to? key}
  end

  description do
    message =  "validate nested #{show child_name}"
    message << " with only: #{show only_keys}" if only_keys.present?
    message << " except: #{show except_keys}"  if except_keys.present?
    message << " with prefix #{show prefix}"   if prefix.present?
    message
  end

  failure_message do
    case
      when common_failure_message
        common_failure_message
      when (missing_child_keys = expected_child_keys - actual_child_keys - invalid_child_keys - [TEST_KEY]).present?
        "#{parent} doesn't nest validations for: #{show missing_child_keys}"
      when actual_keys.empty?
        "parent doesn't nest validations for #{show child_name}"
      when actual_prefix != expected_prefix
        if prefix.present?
          "parent uses a prefix of #{show actual_prefix} rather than #{show expected_prefix}"
        else
          "parent has a prefix of #{show actual_prefix}. Are you missing '.with_prefix(#{show actual_prefix})'?"
        end
      else
        "parent does nest validations for: #{show except_keys & actual_child_keys}"
    end
  end

  failure_message_when_negated do
    case
      when common_failure_message
        common_failure_message
      when (extras = only_keys & actual_child_keys).present?
        "#{parent} does nest #{show child_name} validations for: #{show extras}"
      when except_keys.present?
          "#{parent} doesn't nest #{show child_name} validations for: #{show except_keys - actual_child_keys}"
      when prefix.present?
        "#{parent} does nest validations for: #{show child_name} with a prefix of #{show prefix}"
      else
        "#{parent} does nest validations for: #{show child_name}"
    end
  end

  def common_failure_message
    return "#{parent} doesn't respond to #{show child_name}" unless parent.respond_to?(child_name)
    "#{child_name} doesn't respond to #{show invalid_child_keys}" if  invalid_child_keys.present?
  end

  def show(value)
    Array.wrap(value).map{|key| key.is_a?(Symbol) ? ":#{key}" : key.to_s}.join(', ')
  end

  def combine(*keys)
    keys.flatten.compact
  end
end
