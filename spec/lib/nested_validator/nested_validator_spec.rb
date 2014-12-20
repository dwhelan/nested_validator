require 'spec_helper'
require 'nested_validator'

describe NestedValidator do
  let(:base_class) do
    Class.new {
      include ActiveModel::Validations

      def self.model_name
        ActiveModel::Name.new(self, nil, 'temp')
      end
    }
  end

  let(:nested) do
    Class.new(base_class) {

      attr_accessor :attribute1
      validates     :attribute1, presence: true
    }.new
  end

  subject do
    Class.new(base_class) {

      attr_accessor :nested
      validates     :nested, nested: true
    }.new
  end

  before do
    subject.nested = nested
  end

  describe 'with nested: true' do
    context 'and nested object is valid' do
      before { nested.attribute1 = 'valid' }
      it { should be_valid }
    end

    context 'and nested object is invalid' do
      before { nested.attribute1 = nil }
      it { should_not be_valid }
    end
  end
end
