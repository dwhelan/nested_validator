require 'spec_helper'
require 'nested_validator'

describe 'validates_nested with [parent class with "validates, child1]"' do
  let(:parent_class) do
    Class.new {
      include ActiveModel::Validations

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
    Class.new {
      include ActiveModel::Validations

      attr_accessor :attribute1, :attribute2, :attribute3

      validates :attribute1, presence: true
      validates :attribute2, presence: true
      validates :attribute3, presence: true

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

  describe 'its validations with options:' do
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

      it { should_not validate_nested(:child1) }
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

  describe 'its description for:' do
    let(:validator) { instance_eval self.class.description }

    subject { validator.description }

    context('validate_nested(:child1)')                     { it { should eq 'validate nested :child1' } }
    context('validate_nested(:child1).only(:attribute1)')   { it { should eq 'validate nested :child1 with only: :attribute1' } }
    context('validate_nested(:child1).except(:attribute1)') { it { should eq 'validate nested :child1 except: :attribute1' } }
    context('validate_nested(:child1).with_prefix(:OMG)')   { it { should eq 'validate nested :child1 with prefix :OMG' } }
  end

  describe 'its error messages:' do
    let(:options)   { self.class.parent.description }
    let(:validator) { instance_eval self.class.description }

    describe 'should failure messages for' do
      before { expect(validator.matches? parent).to be false }

      subject { validator.failure_message }

      context 'nested: true' do
        describe('validate_nested(:child2)')             { it { should eq "parent doesn't nest validations for :child2" } }
        describe('validate_nested(:invalid_child_name)') { it { should eq "parent doesn't respond to :invalid_child_name" } }
      end

      context 'nested: {prefix: :OMG}' do
        describe('validate_nested(:child1)')                   { it { should eq "parent has a prefix of :OMG.\nAre you missing '.with_prefix(:OMG)'?" } }
        describe('validate_nested(:child1).with_prefix(:WTF)') { it { should eq "parent uses a prefix of :OMG rather than :WTF" } }
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
