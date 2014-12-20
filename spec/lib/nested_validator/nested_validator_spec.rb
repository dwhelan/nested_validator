require 'spec_helper'
require 'nested_validator'

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
      attr_accessor :child
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

  before do
    child.attribute1 = 'valid'
    child.attribute2 = 'valid'
    child.attribute3 = 'valid'

    subject.child = child
  end

  shared_examples 'should be valid with attributes set to nil' do |*attributes|
    attributes.each do |attribute|
      context "with #{attribute} set to 'nil'" do
        before { child.send("#{attribute}=", nil);subject.valid? }

        it { should be_valid }
        its('errors.messages') { should be_empty }
      end
    end
  end

  shared_examples 'should be invalid with attributes set to nil' do |*attributes|
    attributes.each do |attribute|
      context "with #{attribute} set to 'nil'" do
        before { child.send("#{attribute}=", nil);subject.valid? }

        it { should be_invalid }
        its('errors.messages') { should eq :"child #{attribute}" => ["can't be blank"] }
      end
    end
  end

  describe 'with nested: true' do

    subject { Class.new(parent) { validates :child, nested: true }.new }

    include_examples 'should be invalid with attributes set to nil', :attribute1, :attribute2, :attribute3
  end

  describe 'with "nested: { only: :attribute1 }"' do

    subject { Class.new(parent) { validates :child, nested: { only: :attribute1 } }.new }

    include_examples 'should be invalid with attributes set to nil', :attribute1
    include_examples 'should be valid with attributes set to nil',   :attribute2, :attribute3
  end

  describe 'with "nested: { except: :attribute1 }"' do

    subject { Class.new(parent) { validates :child, nested: { except: :attribute1 } }.new }

    include_examples 'should be valid with attributes set to nil',   :attribute1
    include_examples 'should be invalid with attributes set to nil', :attribute2, :attribute3
  end
end
