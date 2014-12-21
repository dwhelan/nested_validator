require 'spec_helper'
require 'nested_validator'

require 'pry'

describe NestedValidator do
  let(:base) do
    Class.new {
      include ActiveModel::Validations

      def self.model_name
        ActiveModel::Name.new(self, nil, 'temp')
      end
    }
  end

  let(:parent) do
    Class.new(base) {
      attr_accessor :child, :child2
    }
  end

  let(:child) do
    Class.new(base) {

      attr_accessor :attribute1
      validates     :attribute1, presence: true

      attr_accessor :attribute2
      validates     :attribute2, presence: true

      attr_accessor :attribute3
      validates     :attribute3, presence: true
    }.new
  end


  let(:child2) do
    Class.new(base) {

      attr_accessor :attribute1
      validates     :attribute1, presence: true

      attr_accessor :attribute2
      validates     :attribute2, presence: true

      attr_accessor :attribute3
      validates     :attribute3, presence: true
    }.new
  end

  before do
    child.attribute1 = 'valid'
    child.attribute2 = 'valid'
    child.attribute3 = 'valid'

    child2.attribute1 = 'valid'
    child2.attribute2 = 'valid'
    child2.attribute3 = 'valid'

    subject.child = child
    subject.child2 = child2
  end

  def parent_with(&block)
    Class.new(parent) { instance_exec &block }.new
  end

  shared_examples 'excluding' do |child_name, *attributes|
    attributes.each do |attribute|
      context "#{child_name}.#{attribute}" do
        before { send(child_name).send("#{attribute}=", nil);subject.valid? }
        it { should be_valid }
        its('errors.messages') { should be_empty }
      end
    end
  end

  shared_examples 'including' do |child_name, *attributes|
    attributes.each do |attribute|
      context "#{child_name}.#{attribute}" do
        before { send(child_name).send("#{attribute}=", nil);subject.valid? }
        it { should be_invalid }
        its('errors.messages') { should eq :"#{child_name} #{attribute}" => ["can't be blank"] }
      end
    end
  end

  describe 'with "nested: true"' do
    subject { parent_with { validates :child, nested: true } }

    it_should_validate_nested 'including', :child, :attribute1, :attribute2, :attribute3
  end

  describe 'with "nested: { only: :attribute1 }"' do

    subject { Class.new(parent) { validates :child, nested: { only: :attribute1 } }.new }

    it_should_validate_nested 'including', :child, :attribute1
    it_should_validate_nested 'excluding',   :child, :attribute2, :attribute3
  end

  describe 'with "nested: { except: :attribute1 }"' do
    subject { parent_with { validates :child, nested: { except: :attribute1 } } }

    it_should_validate_nested 'excluding', :child, :attribute1
    it_should_validate_nested 'including', :child, :attribute2, :attribute3
  end

  describe 'validates_nested' do

    describe 'with single attribute' do
      subject { parent_with { validates_nested :child } }

      it_should_validate_nested 'including', :child,  :attribute1, :attribute2, :attribute3
    end

    describe 'with multiple attributes' do
      subject { parent_with { validates_nested :child, :child2 } }

      it_should_validate_nested 'including', :child, :attribute1, :attribute2, :attribute3
      it_should_validate_nested 'including', :child2, :attribute1, :attribute2, :attribute3
    end
  end
end
