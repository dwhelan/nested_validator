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

  def failure_message_for(&block)
    validator = block.call
    validator.matches?(subject)
    validator.failure_message
  end

  def failure_message_when_negated(&block)
    validator = block.call
    validator.matches?(subject)
    validator.failure_message_when_negated
  end

  describe 'with no options' do
    subject { with_nested_options true }

    it { should validate_nested(:child1) }
    it { should validate_nested('child1') }

    it { should_not validate_nested(:child2) }
    it { should_not validate_nested('invalid_child_name') }

    describe 'failure message for: validate_nested("child2")' do
      it { expect(failure_message_for{validate_nested 'child2'}).to eq "parent doesn't nest validations for child2" }
    end

    describe 'failure message for: validate_nested("invalid_child_name")' do
      it { expect(failure_message_for{validate_nested 'invalid_child_name'}).to eq 'parent does not respond to invalid_child_name' }
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

    describe 'failure message for: should validate_nested(:child1).only(:invalid_attribute_name)' do
      it { expect(failure_message_for{validate_nested(:child1).only(:invalid_attribute_name)}).to eq "child1 doesn't respond to invalid_attribute_name" }
    end

    describe 'failure message for: should validate_nested(:child1).only(:attribute2)' do
      it { expect(failure_message_for{validate_nested(:child1).only(:attribute2)}).to eq "parent doesn't nest validations for: attribute2" }
    end

    describe 'failure message for: should validate_nested(:child1).only(:attribute1, :attribute2)' do
      it { expect(failure_message_for{validate_nested(:child1).only(:attribute2)}).to eq "parent doesn't nest validations for: attribute2" }
    end

    describe 'failure message for: should_not validate_nested(:child1).only(:attribute1)' do
      it { expect(failure_message_when_negated{validate_nested(:child1).only(:attribute1)}).to eq 'parent does nest validations for: attribute1' }
    end

    describe 'failure message for: should_not validate_nested(:child1).only(:attribute1, :attribute2)' do
      it { expect(failure_message_when_negated{validate_nested(:child1).only(:attribute1, :attribute2)}).to eq 'parent does nest validations for: attribute1' }
    end

    describe 'failure message for: should not validate_nested(:child1).only(:invalid_attribute_name)' do
      it { expect(failure_message_when_negated{validate_nested(:child1).only(:invalid_attribute_name)}).to eq "child1 doesn't respond to invalid_attribute_name" }
    end
  end

  describe 'with "only: [:attribute1, :attribute2]"' do
    subject { with_nested_options only: [:attribute1, :attribute2] }

    it { should_not validate_nested(:child1).only(:attributeX) }
    it { should validate_nested(:child1).only(:attribute1) }
    #it('', :focus) { expect{should validate_nested(:childx).only(:attributeX)}.to raise_error RuntimeError}
    it { should validate_nested(:child1).only(:attribute1, :attribute2) }
    it { should_not validate_nested(:child1).only(:attribute2, :attribute4) }
  end

  describe 'with "except: :attribute1"' do
    subject { with_nested_options except: :attribute1 }

    it { should validate_nested(:child1).except(:attribute1) }
    it { should validate_nested(:child1).except('attribute1') }

    it { should_not validate_nested(:child1).except(:attribute2) }
    #it { should_not validate_nested(:child1).except('attribute1') }
  end

  describe 'with "except: [:attribute1, :attribute2]"' do
    subject { with_nested_options except: [:attribute1, :attribute2] }

    it { should validate_nested(:child1).except(:attribute1, :attribute2) }
    #it { should_not validate_nested(:child1).except(:attribute1, :attribute2) }
  end
end
