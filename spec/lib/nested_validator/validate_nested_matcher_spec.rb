require 'spec_helper'
require 'nested_validator'

describe 'validates_nested' do
  let(:base_class) do
    Class.new {
      include ActiveModel::Validations

      # To keep ActiveModel happy
      def self.model_name
        ActiveModel::Name.new(self, nil, 'temp')
      end
    }
  end

  let(:parent_class) do
    Class.new(base_class) {
      attr_accessor :child1, :child2

      def to_s
        'parent'
      end
    }

  end

  let(:child_class) do
    Class.new(base_class) {
      attr_accessor :attribute1
      validates     :attribute1, presence: true

      attr_accessor :attribute2
      validates     :attribute2, presence: true

      attr_accessor :attribute3
      validates     :attribute3, presence: true

      def initialize
        @attribute1 = 'valid'
        @attribute2 = 'valid'
        @attribute3 = 'valid'
      end
    }
  end

  let(:child1) { child_class.new }
  let(:child2) { child_class.new }

  def parent_with(&block)
    parent = Class.new(parent_class) { instance_exec &block }.new
    parent.child1 = child1
    parent.child2 = child2
    parent
  end

  def with_nested_options(options)
    parent_with { validates :child1, nested: options }
  end

  def validator_should_fail(block)
    validator = block.call
    expect(validator.matches? subject).to be false
    validator
  end

  def should_fail_with(message, &block)
    validator = block.call
    expect(validator.matches? subject).to be false
    expect(validator.failure_message).to eq message
  end

  def should_fail_negated_with(message, &block)
    validator = block.call
    expect(validator.matches? subject).to be true
    expect(validator.failure_message_when_negated).to eq message
  end

  describe 'with no options' do
    subject { with_nested_options true }

    it { should validate_nested(:child1) }
    it { should validate_nested('child1') }

    it { should_not validate_nested(:child2) }
    it { should_not validate_nested(:invalid_child_name) }

    describe 'failure message for: should validate_nested(:child2)' do
      it { should_fail_with("parent doesn't nest validations for :child2") { validate_nested :child2 } }
    end

    describe 'failure message for: should validate_nested(:invalid_child_name)' do
      it { should_fail_with("parent doesn't respond to :invalid_child_name") { validate_nested :invalid_child_name } }
    end

    describe 'failure message for: should_not validate_nested(:child1)' do
      it { should_fail_negated_with('parent does nest validations for: :child1') { validate_nested :child1 } }
    end
  end

  describe 'with prefix "OMG"' do
    subject { with_nested_options prefix: 'OMG' }

    it { should validate_nested(:child1).with_prefix('OMG') }
    it { should validate_nested(:child1).with_prefix(:OMG) }

    it { should_not validate_nested(:child1).with_prefix('WTF') }
    it { should_not validate_nested(:child1).with_prefix(:WTF) }
  end

  describe 'with prefix :OMG' do
    subject { with_nested_options prefix: :OMG }

    it { should validate_nested(:child1).with_prefix('OMG') }
    it { should validate_nested(:child1).with_prefix(:OMG) }

    it { should_not validate_nested(:child1).with_prefix('WTF') }
    it { should_not validate_nested(:child1).with_prefix(:WTF) }
  end

  describe 'with "only: :attribute1"' do
    subject { with_nested_options only: :attribute1 }

    it { should validate_nested(:child1).only(:attribute1) }
    it { should validate_nested(:child1).only('attribute1') }

    it { should_not validate_nested(:child1).only(:attribute2) }
    it { should_not validate_nested(:child1).only('attribute2') }
    it { should_not validate_nested(:child1).only(:invalid_attribute_name) }
    it { should_not validate_nested(:child1).only(:attribute1, :attribute2) }

    describe 'failure message for: should validate_nested(:child1).only(:invalid_attribute_name)' do
      it { should_fail_with("child1 doesn't respond to :invalid_attribute_name") { validate_nested(:child1).only(:invalid_attribute_name) } }
    end

    describe 'failure message for: should validate_nested(:child1).only(:attribute2)' do
      it { should_fail_with("parent doesn't nest validations for: attribute2") { validate_nested(:child1).only(:attribute2) } }
    end

    describe 'failure message for: should validate_nested(:child1).only(:attribute1, :attribute2)' do
      it { should_fail_with("parent doesn't nest validations for: attribute2") { validate_nested(:child1).only(:attribute1, :attribute2) } }
    end

    describe 'failure message for: should_not validate_nested(:child1).only(:attribute1)' do
      it { should_fail_negated_with('parent does nest :child1 validations for: :attribute1') { validate_nested(:child1).only(:attribute1) } }
    end
  end

  describe 'with "only: [:attribute1, :attribute2]"' do
    subject { with_nested_options only: [:attribute1, :attribute2] }

    it { should validate_nested(:child1).only(:attribute1) }
    it { should validate_nested(:child1).only(:attribute2) }
    it { should validate_nested(:child1).only(:attribute1, :attribute2) }
    it { should validate_nested(:child1).only('attribute1', 'attribute2') }

    it { should_not validate_nested(:child1).only(:attribute2, :attribute4) }
    it { should_not validate_nested(:child1).only(:invalid_attribute_name) }

    describe 'failure message for: should_not validate_nested(:child1).only(:attribute1, :attribute2)' do
      it { should_fail_negated_with('parent does nest :child1 validations for: :attribute1, :attribute2') { validate_nested(:child1).only(:attribute1, :attribute2) } }
    end
  end

  describe 'with "except: :attribute1"' do
    subject { with_nested_options except: :attribute1 }

    it { should validate_nested(:child1).except(:attribute1) }
    it { should validate_nested(:child1).except('attribute1') }

    it { should_not validate_nested(:child1).except(:attribute2) }

    describe 'failure message for: should validate_nested(:child1).except(:invalid_attribute_name)' do
      it { should_fail_with("child1 doesn't respond to :invalid_attribute_name") { validate_nested(:child1).except(:invalid_attribute_name) } }
    end

    describe 'failure message for: should validate_nested(:child1).except(:attribute2)' do
      it { should_fail_with('parent does nest validations for: :attribute2') { validate_nested(:child1).except(:attribute2) } }
    end

    describe 'failure message for: should validate_nested(:child1).except(:attribute1, :attribute2)' do
      it { should_fail_with('parent does nest validations for: :attribute2') { validate_nested(:child1).except(:attribute1, :attribute2) } }
    end

    describe 'failure message for: should_not validate_nested(:child1).except(:attribute1)' do
      it { should_fail_negated_with('parent does nest :child1 validations for: :attribute1') { validate_nested(:child1).except(:attribute1) } }
    end
  end

  describe 'with "except: [:attribute1, :attribute2]"' do
    subject { with_nested_options except: [:attribute1, :attribute2] }

    it { should validate_nested(:child1).except(:attribute1, :attribute2) }

    describe 'failure message for: should_not validate_nested(:child1).except(:attribute1, :attribute2)' do
      it { should_fail_negated_with('parent does nest :child1 validations for: :attribute1, :attribute2') { validate_nested(:child1).except(:attribute1, :attribute2) } }
    end
  end
end
