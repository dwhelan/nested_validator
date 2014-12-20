require 'spec_helper'
require 'nested_validator'

describe NestedValidator do
  subject do
    validatable = Class.new do
      include ActiveModel::Validations

      def self.model_name
        ActiveModel::Name.new(self, nil, 'temp')
      end

      attr_accessor :child
      validates     :child, nested: true
    end
    validatable.new
  end

  it { should_not be_nil }
end
