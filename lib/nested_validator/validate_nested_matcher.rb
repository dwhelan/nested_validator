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
#       it { should validate_nested(:child).any(:attribute1, :attribute2) }
#     end
RSpec::Matchers.define :validate_nested do |child_name|

  [:child_name, :prefix, :only_keys, :except_keys, :any_keys, :parent, :child_attributes, :child_error_key].each do |attr|
    define_method(attr) do
      instance_variable_get "@#{attr}"
    end

    define_method("#{attr}=") do |value|
      instance_variable_set "@#{attr}", value
    end
  end

  TEST_KEY ||= :__test_key__

  match do |parent|
    self.prefix      ||= ''
    self.only_keys   ||= []
    self.except_keys ||= []
    self.any_keys    ||= []

    self.child_name  = child_name.to_sym
    self.parent      = parent

    return false unless parent.respond_to? child_name
    return false if invalid_child_keys.present?

    self.child_attributes = child_attributes_when_validity_is(false) - child_attributes_when_validity_is(true)
    self.child_error_key  = (child_error_keys_when_validity_is(false) - child_error_keys_when_validity_is(true)).first

    child_attributes == expected_child_attributes && child_error_key == expected_child_error_key
  end

  def prepare_keys(keys)
    if keys.length == 1 && keys[0].is_a?(String)
      keys[0].split(/\s+|,/).reject(&:blank?)
    else
      keys
    end
  end

  chain(:with_prefix) { |prefix|  self.prefix      = prefix.to_sym }
  chain(:only)        { |*only|   self.only_keys   = prepare_keys(only)   }
  chain(:except)      { |*except| self.except_keys = prepare_keys(except) }
  chain(:any)         { |*any|    self.any_keys    = prepare_keys(any) }

  def child
    parent.public_send(child_name)
  end

  def child_attributes_when_validity_is(valid)
    errors_when_child_validity_is(valid).map{|k, msg| msg.split.first.to_sym}
  end

  def child_error_keys_when_validity_is(valid)
    errors_when_child_validity_is(valid).keys
  end

  def errors_when_child_validity_is(valid)
    child_error_keys = combine TEST_KEY, only_keys, except_keys, any_keys
    child_errors     = child_error_keys.inject({}) { |result, key| result[key] = ['error message']; result }

    allow(child).to receive(:valid?) { valid }
    allow(child).to receive(:errors) { valid ? [] : child_errors }

    parent.valid?
    parent.errors
  end

  def expected_child_attributes
    expected_child_keys.map{|k| k.to_sym}
  end

  def expected_child_error_key
    prefix.present? ? prefix : child_name
  end

  def expected_child_keys
    expected_keys = case
      when only_keys.present?
        only_keys
      when any_keys.present?
        any_keys
      else
        [TEST_KEY]
    end
    unique_except_keys = except_keys - only_keys - any_keys
    combine expected_keys - unique_except_keys
  end

  def actual_child_keys
    child_attributes.map{|key| key.to_s.sub(/^.*\s+/, '').to_sym }
  end

  def invalid_child_keys
    (only_keys + except_keys).reject{|key| child.respond_to? key}
  end

  description do
    message =  "validate nested #{show child_name}"
    message << " with only: #{show only_keys}" if only_keys.present?
    message << " except: #{show except_keys}"  if except_keys.present?
    message << " any: #{show any_keys}"        if any_keys.present?
    message << " with prefix #{show prefix}"   if prefix.present?
    message
  end

  failure_message do
    case
      when common_failure_message
        common_failure_message
      when (missing_child_keys = expected_child_keys - actual_child_keys - invalid_child_keys - [TEST_KEY]).present?
        "#{parent} doesn't nest validations for: #{show missing_child_keys}"
      when child_attributes.empty?
        "parent doesn't nest validations for #{show child_name}"
      when child_error_key != expected_child_error_key
        if prefix.present?
          "parent uses a prefix of #{show child_error_key} rather than #{show expected_child_error_key}"
        else
          "parent has a prefix of #{show child_error_key}. Are you missing '.with_prefix(#{show child_error_key})'?"
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
