require 'spec_helper'
require 'nested_validator'

describe 'validates_nested against parent class with "validates, child1"' do
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

      def initialize(child1=nil, child2=nil)
        self.child1 = child1
        self.child2 = child2
      end

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

  let(:parent)  { parent_class.new child_class.new, child_class.new }
  let(:options) { { presence: true } }

  before { parent_class.class_eval "validates :child1, #{options}" }

  describe 'validations with options' do
    let(:options) { self.class.description }

    subject { parent }

    context 'nested: true' do
      it { should validate_nested(:child1) }
      it { should validate_nested('child1') }

      it { should_not validate_nested(:child2) }
      it { should_not validate_nested(:invalid_child_name) }
    end

    context 'nested: {prefix: "OMG"}' do
      it { should validate_nested(:child1).with_prefix('OMG') }
      it { should validate_nested(:child1).with_prefix(:OMG) }

      it { should_not validate_nested(:child1).with_prefix('WTF') }
      it { should_not validate_nested(:child1).with_prefix(:WTF) }
    end

    context 'nested: {only: :attribute1}' do
      it { should validate_nested(:child1).only(:attribute1) }
      it { should validate_nested(:child1).only('attribute1') }

      it { should_not validate_nested(:child1).only(:attribute2) }
      it { should_not validate_nested(:child1).only('attribute2') }
      it { should_not validate_nested(:child1).only(:invalid_attribute_name) }
      it { should_not validate_nested(:child1).only(:attribute1, :attribute2) }
    end

    context 'nested: {only: [:attribute1, :attribute2]}' do
      it { should validate_nested(:child1).only(:attribute1) }
      it { should validate_nested(:child1).only(:attribute2) }
      it { should validate_nested(:child1).only(:attribute1, :attribute2) }
      it { should validate_nested(:child1).only('attribute1', 'attribute2') }

      it { should_not validate_nested(:child1).only(:attribute2, :attribute3) }
      it { should_not validate_nested(:child1).only(:invalid_attribute_name) }
    end

    context 'nested: {except: :attribute1}' do
      it { should validate_nested(:child1).except(:attribute1) }
      it { should validate_nested(:child1).except('attribute1') }

      it { should_not validate_nested(:child1).except(:attribute2) }
    end

    context 'nested: {except: [:attribute1, :attribute2]}' do
      it { should validate_nested(:child1).except(:attribute1, :attribute2) }
    end
  end

  describe 'description for:' do
    let(:validator) { instance_eval self.class.description }

    subject { validator.description }

    context('validate_nested(:child1)')                     { it { should eq 'validate nested :child1' } }
    context('validate_nested(:child1).only(:attribute1)')   { it { should eq 'validate nested :child1 with only: :attribute1' } }
    context('validate_nested(:child1).except(:attribute1)') { it { should eq 'validate nested :child1 except: :attribute1' } }
    context('validate_nested(:child1).with_prefix(:OMG)')   { it { should eq 'validate nested :child1 with prefix :OMG' } }
  end

  describe 'error messages' do
    let(:options) { self.class.parent.description }
    let(:validator) { instance_eval self.class.description }

    before { validator.matches? parent }

    describe 'should failure messages for' do
      before { expect(validator.matches? parent).to be false }

      subject { validator.failure_message }

      context 'nested: true' do
        describe('validate_nested(:child2)')             { it { should eq "parent doesn't nest validations for :child2" } }
        describe('validate_nested(:invalid_child_name)') { it { should eq "parent doesn't respond to :invalid_child_name" } }
      end

      context 'nested: {only: :attribute1}' do
        describe('validate_nested(:child1).only(:invalid_attribute_name)')  { it { should eq "child1 doesn't respond to :invalid_attribute_name" } }
        describe('validate_nested(:child1).only(:attribute2)')              { it { should eq "parent doesn't nest validations for: :attribute2"  } }
        describe('validate_nested(:child1).only(:attribute1, :attribute2)') { it { should eq "parent doesn't nest validations for: :attribute2"  } }
      end

      context 'nested: {except: :attribute1}' do
        describe('validate_nested(:child1).except(:invalid_attribute_name)')  { it { should eq "child1 doesn't respond to :invalid_attribute_name"  } }
        describe('validate_nested(:child1).except(:attribute2)')              { it { should eq 'parent does nest validations for: :attribute2' } }
        describe('validate_nested(:child1).except(:attribute1, :attribute2)') { it { should eq 'parent does nest validations for: :attribute2' } }
      end
    end

    describe 'should_not failure messages for' do
      before { expect(validator.matches? parent).to be true }

      subject { validator.failure_message_when_negated }

      context 'nested: true' do
        describe('validate_nested(:child1)') { it { should eq 'parent does nest validations for: :child1' } }
      end

      context 'nested: {only: :attribute1}' do
        describe('validate_nested(:child1).only(:attribute1)') { it { should eq 'parent does nest :child1 validations for: :attribute1' } }
      end

      context 'nested: {only: [:attribute1, :attribute2]}' do
        describe('validate_nested(:child1).only(:attribute1)')              { it { should eq 'parent does nest :child1 validations for: :attribute1' } }
        describe('validate_nested(:child1).only(:attribute1, :attribute2)') { it { should eq 'parent does nest :child1 validations for: :attribute1, :attribute2' } }
      end

      context 'nested: {except: :attribute1}' do
        describe('validate_nested(:child1).except(:attribute1)') { it { should eq "parent doesn't nest :child1 validations for: :attribute1" } }
      end

      context 'nested: {except: [:attribute1, :attribute2]}' do
        describe('validate_nested(:child1).except(:attribute1)')              { it { should eq "parent doesn't nest :child1 validations for: :attribute1" } }
        describe('validate_nested(:child1).except(:attribute1, :attribute2)') { it { should eq "parent doesn't nest :child1 validations for: :attribute1, :attribute2" } }
      end
    end
  end
end
