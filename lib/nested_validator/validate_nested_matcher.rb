
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
    :"#{actual_keys.first.to_s.sub(/\s+#{TEST_KEY}$/, '')}"
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

  description do
    message = "validate nested :#{child_name}"
    message << " with only #{only_keys.join(', ')}" if only_keys.present?
    message << " except #{except_keys.join(', ')}"  if except_keys.present?
    message << " with prefix #{prefix}"             if prefix.present?
    message
  end

  failure_message do
    return "#{parent} does not respond to #{child_name}" unless parent.respond_to? child_name

    message = ''
    hints = ''

    if invalid_attribute_keys.present?
      message << "#{child_name} doesn't respond to #{invalid_attribute_keys.join(', ')}"
    elsif missing_child_keys.present?
      message << "#{parent} doesn't nest validations for: #{missing_child_keys.join(', ')}"
    elsif actual_prefix != expected_prefix
      message << "parent doesn't nest validations for #{child_name}"
    end



    if actual_keys.present?
      message << "#{child_name} was validated"
      if (unexpected_child_keys = actual_child_keys - expected_child_keys).present?
        message << " but got unexpected errors for '#{unexpected_child_keys.join(', ')}'"
      end
    end

    message << hints
    message
  end

  failure_message_when_negated do
    messages = []

    if (extras = only_keys & actual_child_keys).present?
      messages << "#{parent} does nest validations for: #{extras.join(', ')}"
    end
    messages << "#{child_name} doesn't respond to #{invalid_attribute_keys.join(', ')}" if invalid_attribute_keys.present?
    messages << "#{parent} was valid even though one of #{child_name} attributes '#{except_keys.join(', ')}' was invalid" if except_keys.present?

    messages.join(' and ')
  end

  chain(:with_prefix) { |prefix|  self.prefix      = prefix.to_s }
  chain(:only)        { |*only|   self.only_keys   = only.map(&:to_sym) }
  chain(:except)      { |*except| self.except_keys = except.map(&:to_sym) }
end
