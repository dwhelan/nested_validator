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

  describe 'with no options' do
    subject { with_nested_options true }

    it { should validate_nested(:child1) }
    it { should_not validate_nested(:child2) }
  end

  describe 'with prefix option' do
    subject { with_nested_options prefix: 'Omg' }

    it { should validate_nested(:child1).with_prefix('Omg') }
    it { should_not validate_nested(:child1) }
  end

  describe 'with only option', :focus do
    subject { with_nested_options only: :attribute1 }

    it { should validate_nested(:child1).only(:attribute1) }
  end
end
