require 'spec_helper'
require 'nested_validator'

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

  def with_nested_options(options)
    parent_with { validates :child1, nested: options }
  end

  shared_examples 'valid:' do |child_name, *attributes|
    attributes.each do |attribute|
      specify "when #{child_name}.#{attribute} set to nil" do
        send(child_name).send("#{attribute}=", nil)
        expect(subject).to be_valid
      end
    end
  end

  shared_examples 'invalid:' do |child_name, *attributes|
    attributes.each do |attribute|
      specify "when #{child_name}.#{attribute} set to nil" do
        send(child_name).send("#{attribute}=", nil)
        expect(subject).to be_invalid
      end
    end
  end

  describe 'with "nested: true"' do
    subject { with_nested_options true }

    it_should_validate_nested 'invalid:', :child1, :attribute1, :attribute2, :attribute3
  end

  describe 'error messages' do
    context 'with scalar values' do
      before  { child1.attribute1 = nil;subject.valid? }

      describe 'with no prefix' do
        subject { with_nested_options true }

        its('errors.messages') { should eq :'child1 attribute1' => ["can't be blank"] }
      end

      describe 'with "prefix: "OMG"', :focus do
        subject { with_nested_options prefix: 'OMG' }

        its('errors.messages') { puts subject.errors.messages; should eq :'OMG attribute1' => ["can't be blank"] }
      end

      describe 'with "prefix: ""' do
        subject { with_nested_options prefix: '' }

        its('errors.messages') { should eq :'attribute1' => ["can't be blank"] }
      end
    end

    context 'with an array of values' do
      let(:child1) { [child_class.new, child_class.new]  }

      before  { child1[0].attribute1 = nil;subject.valid? }
      subject { with_nested_options true }

      describe 'with single invalid value' do
        its('errors.messages') { should eq :'child1[0] attribute1' => ["can't be blank"] }
      end

      describe 'with multiple invalid values' do
        before  { child1[1].attribute1 = nil;subject.valid? }
        its('errors.messages') { should include :'child1[0] attribute1' => ["can't be blank"] }
        its('errors.messages') { should include :'child1[1] attribute1' => ["can't be blank"] }
      end

      context 'with a prefix' do
        subject { with_nested_options prefix: 'OMG' }

        its('errors.messages') { should eq :'OMG[0] attribute1' => ["can't be blank"] }
      end
    end
  end

  context 'with a hash of values' do
    let(:child1) { { first: child_class.new, second: child_class.new }  }

    before  { child1[:first].attribute1 = nil;subject.valid? }
    subject { with_nested_options true }

    describe 'with single invalid value' do
      its('errors.messages') { should eq :'child1[first] attribute1' => ["can't be blank"] }
    end

    describe 'with multiple invalid values' do
      before  { child1[:second].attribute1 = nil;subject.valid? }
      its('errors.messages') { should include :'child1[first] attribute1' => ["can't be blank"] }
      its('errors.messages') { should include :'child1[second] attribute1' => ["can't be blank"] }
    end

    context 'with a prefix' do
      subject { with_nested_options prefix: 'OMG' }

      its('errors.messages') { should eq :'OMG[first] attribute1' => ["can't be blank"] }
    end
  end

  describe '"validates :child1, nested: {only: ...}"' do

    describe 'with "only: :attribute1"' do

      subject { with_nested_options only: :attribute1 }

      it_should_validate_nested 'invalid:', :child1, :attribute1
      it_should_validate_nested 'valid:',   :child1, :attribute2, :attribute3
    end

    describe 'with "only: [:atnested_validator_spec.rbtribute1, :attribute2]"' do

      subject { parent_with { validates :child1, nested: { only: [:attribute1, :attribute2] } } }

      it_should_validate_nested 'invalid:', :child1, :attribute1, :attribute2
      it_should_validate_nested 'valid:',   :child1, :attribute3
    end
  end

  describe '"validates :child1, nested: {except: ...}"' do
    describe 'with "except: :attribute1"' do
      subject { with_nested_options except: :attribute1 }

      it_should_validate_nested 'invalid:', :child1, :attribute2, :attribute3
      it_should_validate_nested 'valid:',   :child1, :attribute1
    end

    describe 'with "except: [:attribute1, :attribute2"' do
      subject { with_nested_options except: [:attribute1, :attribute2] }

      it_should_validate_nested 'invalid:', :child1, :attribute3
      it_should_validate_nested 'valid:',   :child1, :attribute1, :attribute2
    end
  end

  describe 'attributes in "only" option should take precedence over "except"' do
    describe '"validates :child1, nested: {only: attribute1, except: :attribute1}"' do
      subject { with_nested_options only: :attribute1, except: :attribute1 }

      it_should_validate_nested 'invalid:', :child1, :attribute1
      it_should_validate_nested 'valid:',   :child1, :attribute2, :attribute3
    end
  end

  describe 'validates_nested' do

    describe 'validates_nested :child1' do
      subject { parent_with { validates_nested :child1 } }

      it_should_validate_nested 'invalid:', :child1,  :attribute1, :attribute2, :attribute3
      it_should_validate_nested 'valid:',   :child2,  :attribute1, :attribute2, :attribute3
    end

    describe 'validates_nested :child1, :child2' do
      subject { parent_with { validates_nested :child1, :child2 } }

      it_should_validate_nested 'invalid:', :child1, :attribute1, :attribute2, :attribute3
      it_should_validate_nested 'invalid:', :child2, :attribute1, :attribute2, :attribute3
    end

    describe 'validates_nested :child1, :child2, only: :attribute1' do
      subject { parent_with { validates_nested :child1, :child2, only: :attribute1 } }

      it_should_validate_nested 'invalid:', :child1, :attribute1
      it_should_validate_nested 'invalid:', :child2, :attribute1
      it_should_validate_nested 'valid:',   :child1, :attribute2, :attribute3
      it_should_validate_nested 'valid:',   :child2, :attribute2, :attribute3
    end
  end
end
