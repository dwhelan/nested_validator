require 'spec_helper'
require 'nested_validator'


describe 'Typical usage' do
  class Child
    include ActiveModel::Validations

    attr_accessor :attribute1, :attribute2
    validates :attribute1, presence: true
    validates :attribute2, presence: true
  end

  class ParentBase
    include ActiveModel::Validations

    attr_accessor :child

    def initialize
      self.child = Child.new
    end
  end

  specify 'simple example' do
    class Parent < ParentBase
      validates :child, nested: true
    end

    parent = Parent.new
    parent.valid?
    puts parent.errors.messages
  end

  specify 'only certain child attributes' do
    class ParentOnly < ParentBase
      validates :child, nested: { only: :attribute1 }
    end

    parent = ParentOnly.new
    parent.valid?
    puts parent.errors.messages
  end

  specify 'except certain child attributes' do
    class ParentExcept < ParentBase
      validates :child, nested: { except: :attribute2 }
    end

    parent = ParentExcept.new
    parent.valid?
    puts parent.errors.messages
  end

  specify 'custom message prefix' do
    class ParentPrefix < ParentBase
      validates :child, nested: { only: :attribute1, prefix: 'OMG'}
    end

    parent = ParentPrefix.new
    parent.valid?
    puts parent.errors.messages
  end

  specify 'array of values' do
    class ParentArray < ParentBase
      validates :child, nested: { only: :attribute1 }
    end

    parent = ParentArray.new
    parent.child = [Child.new] * 2
    parent.valid?
    puts parent.errors.messages
  end

  specify 'hash of values' do
    class ParentHash < ParentBase
      validates :child, nested: { only: :attribute1 }
    end

    parent = ParentHash.new
    parent.child = { thing1: Child.new, thing2: Child.new }
    parent.valid?
    puts parent.errors.messages
  end
end
