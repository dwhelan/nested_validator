require 'spec_helper'
require 'nested_validator'

require 'pry'

describe NestedValidator do
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

  shared_examples 'excluding' do |child_name, *attributes|
    attributes.each do |attribute|
      context "with #{child_name}.#{attribute} set to nil" do
        before { send(child_name).send("#{attribute}=", nil);subject.valid? }
        it { should be_valid }
        its('errors.messages') { should be_empty }
      end
    end
  end

  shared_examples 'including' do |child_name, *attributes|
    attributes.each do |attribute|
      context "with #{child_name}.#{attribute} set to nil" do
        before { send(child_name).send("#{attribute}=", nil);subject.valid? }
        it { should be_invalid }
        its('errors.messages') { should eq :"#{child_name} #{attribute}" => ["can't be blank"] }
      end
    end
  end

  describe 'with "nested: true"' do
    subject { parent_with { validates :child1, nested: true } }

    it_should_validate_nested 'including', :child1, :attribute1, :attribute2, :attribute3
  end

  describe 'with "nested: { only: :attribute1 }"' do

    subject { parent_with { validates :child1, nested: { only: :attribute1 } } }

    it_should_validate_nested 'including', :child1, :attribute1
    it_should_validate_nested 'excluding',   :child1, :attribute2, :attribute3
  end

  describe 'with "nested: { except: :attribute1 }"' do
    subject { parent_with { validates :child1, nested: { except: :attribute1 } } }

    it_should_validate_nested 'excluding', :child1, :attribute1
    it_should_validate_nested 'including', :child1, :attribute2, :attribute3
  end

  describe 'validates_nested' do

    describe 'with single attribute' do
      subject { parent_with { validates_nested :child1 } }

      it_should_validate_nested 'including', :child1,  :attribute1, :attribute2, :attribute3
      it_should_validate_nested 'excluding', :child2,  :attribute1, :attribute2, :attribute3
    end

    describe 'with multiple attributes' do
      subject { parent_with { validates_nested :child1, :child2 } }

      it_should_validate_nested 'including', :child1, :attribute1, :attribute2, :attribute3
      it_should_validate_nested 'including', :child2, :attribute1, :attribute2, :attribute3
    end

    describe 'with options' do
      subject { parent_with { validates_nested :child1, only: :attribute1 } }

      it_should_validate_nested 'including', :child1, :attribute1
      it_should_validate_nested 'excluding', :child1, :attribute2, :attribute3
    end
  end
end
