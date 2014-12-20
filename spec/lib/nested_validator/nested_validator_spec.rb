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

  describe 'with nested: true' do

    subject { Class.new(parent) { validates :child, nested: true }.new }

    context('and all attributes valid')  { it { should  be_valid } }

    context('and attribute1 is invalid') { before { child.attribute1 = nil }; it { should_not be_valid } }
    context('and attribute2 is invalid') { before { child.attribute2 = nil }; it { should_not be_valid } }
    context('and attribute3 is invalid') { before { child.attribute3 = nil }; it { should_not be_valid } }
  end

  describe 'with "nested: { only: :attribute1 }"' do

    subject { Class.new(parent) { validates :child, nested: { only: :attribute1 } }.new }

    context('and all attributes valid')  { it { should  be_valid } }

    context('and attribute1 is invalid') { before { child.attribute1 = nil }; it { should_not be_valid } }
    context('and attribute2 is invalid') { before { child.attribute2 = nil }; it { should     be_valid } }
    context('and attribute3 is invalid') { before { child.attribute3 = nil }; it { should     be_valid } }
  end
end
