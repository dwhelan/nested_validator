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

  attr_accessor :parent, :child_name, :child, :prefix, :actual_keys, :only_keys, :except_keys

  match do |parent|
    self.prefix      ||= ''
    self.only_keys   ||= []
    self.except_keys ||= []

    self.child_name  = child_name
    self.parent      = parent

    return false unless parent.respond_to? child_name

    self.child       = parent.send child_name
    self.actual_keys = (invalid_error_keys - valid_error_keys)

    #binding.pry
    actual_child_keys == expected_child_keys
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
    keys = only_keys.empty? ? [TEST_KEY] : only_keys
    unique_except_keys = except_keys - keys
    keyify keys - unique_except_keys
  end

  def actual_child_keys
    actual_keys.map{|key| key.to_s.sub(/^.*\s+/, '').to_sym }#.reject{|key| key.to_sym == TEST_KEY}
  end

  def child_errors
    child_keys.inject({}){|result, key| result[key] = ['error message'];result }
  end

  TEST_KEY ||= :__unique_key__

  def child_keys
    keyify TEST_KEY, only_keys, except_keys
  end

  def keyify(*keys)
    keys.flatten.compact
  end

  def expected_prefix
    prefix.present? ? prefix : child_name
  end

  def actual_prefix
    :"#{actual_keys.first.to_s.split.first}"
  end

  def missing_child_keys
    expected_child_keys - actual_child_keys - invalid_attribute_keys - [TEST_KEY]
  end

  def invalid_attribute_keys
    expected_attributes = keyify only_keys, except_keys
    expected_attributes.reject{|attribute| child.respond_to? attribute}
  end

  def invalid_attribute_names
    invalid_attribute_keys.join(', ')
  end


  def join(keys)
    keys.map { |key| show(key) }.join(', ')
  end

  def show(value)
    if value.respond_to?(:map)
      value.map { |key| show(key) }.join(', ')
    elsif value.is_a?(Symbol)
      ":#{value}"
    else
      value.to_s
    end
  end

  description do
    message = "validate nested #{show(child_name)}"
    message << " with only #{join(only_keys)}" if only_keys.present?
    message << " except #{join(except_keys)}"  if except_keys.present?
    message << " with prefix #{show(prefix)}"  if prefix.present?
    message
  end

  failure_message do
    case
      when !parent.respond_to?(child_name)
        "#{parent} doesn't respond to #{show child_name}"
      when invalid_attribute_keys.present?
        "#{child_name} doesn't respond to #{show invalid_attribute_keys}"
      when missing_child_keys.present?
        "#{parent} doesn't nest validations for: #{missing_child_keys.join(', ')}"
      when actual_prefix != expected_prefix
        "parent doesn't nest validations for #{show child_name}"
      else
        "parent does nest validations for: #{show except_keys & actual_child_keys}"
    end
  end

  failure_message_when_negated do
    return "#{parent} doesn't respond to #{show child_name}" unless parent.respond_to? child_name

    messages = []

    #binding.pry
    if (extras = only_keys & actual_child_keys).present?
      messages << "#{parent} does nest #{show child_name} validations for: #{show extras}"
    elsif only_keys.present?
    elsif except_keys.present?
        messages << "#{parent} does nest #{show child_name} validations for: #{show except_keys - actual_child_keys}"
    else
      messages << "#{parent} does nest validations for: #{show child_name}"
    end
    messages << "#{child_name} doesn't respond to #{show invalid_attribute_keys}" if invalid_attribute_keys.present?
    #messages << "#{parent} was valid even though one of #{child_name} attributes '#{except_keys.join(', ')}' was invalid" if except_keys.present?

    messages.join(' and ')
  end

  chain(:with_prefix) { |prefix|  self.prefix      = prefix }
  chain(:only)        { |*only|   self.only_keys   = only   }
  chain(:except)      { |*except| self.except_keys = except }
end
