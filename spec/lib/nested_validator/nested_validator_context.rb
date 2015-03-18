require 'spec_helper'
require 'nested_validator'

shared_context 'nested validator' do
  let(:parent_class) do
    opts = options
    Class.new {
      include ActiveModel::Validations

      attr_accessor :child, :other

      instance_eval "validates :child, nested: #{opts}"

      def initialize(child=nil)
        self.child = child
        self.other = ''
      end

      def to_s
        'parent'
      end
    }
  end

  let(:options) { 'true' }

  let(:child_class) do
    Class.new {
      include ActiveModel::Validations

      attr_accessor :attribute, :attribute2, :attribute3

      validates :attribute, presence: true
      validates :attribute2, presence: true
      validates :attribute3, presence: true

      def self.model_name
        ActiveModel::Name.new(self, nil, 'temp')
      end
    }
  end
end
