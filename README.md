[![Gem Version](https://badge.fury.io/rb/nested_validator.png)](https://badge.fury.io/rb/nested_validator.png)
[![Build Status](https://travis-ci.org/dwhelan/nested_validator.png?branch=master)](https://travis-ci.org/dwhelan/nested_validator)
[![Code Climate](https://codeclimate.com/github/ericroberts/percentable.png)](https://codeclimate.com/github/ericroberts/percentable)
[![Coverage Status](https://coveralls.io/repos/ericroberts/percentable/badge.png?branch=master)](https://coveralls.io/r/ericroberts/percentable?branch=master)

# Nested Validator

Nested validations allow a parent's class validity to include those of child
attributes. Errors messages will be copied from the child attribute to the parent.

## Installation

Add this line to your application's Gemfile:

    gem 'nested_validator'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install nested_validator

## Usage

Assume we have a parent object and we want its validaty to depend on its child validity:

``` ruby
class ParentBase
  include ActiveModel::Validations

  attr_accessor :child

  def initialize
    self.child = Child.new
  end
end

class Child
  include ActiveModel::Validations

  attr_accessor :attribute1, :attribute2
  
  validates :attribute1, presence: true
  validates :attribute2, presence: true
end
```

Well, we can use a nested validation to do just that:

``` ruby
class Parent < ParentBase
  validates :child, nested: true
end

parent = Parent.new
parent.valid?
puts parent.errors.messages

 # => {:"child attribute1"=>["can't be blank"], :"child attribute2"=>["can't be blank"]}
```
### What if I want to validate with just some of the child attributes?

You can use an ```only``` option like this:

``` ruby
class ParentOnly < ParentBase
  validates :child, nested: { only: :attribute1 }
end

parent = ParentOnly.new
parent.valid?
puts parent.errors.messages

 # => {:"child attribute1"=>["can't be blank"]}
```

You can also provide an array of attributes to ```only``` if you want to include more than one.

### OK, is there a way to exclude some child attributes?

Sure thing. You can use the ```except``` option:

``` ruby
class ParentExcept < ParentBase
  validates :child, nested: { except: :attribute2 }
end

parent = ParentExcept.new
parent.valid?
puts parent.errors.messages

 # => {:"child attribute1"=>["can't be blank"]}
```

### Alright, what if I want a custom message?

You can specify a ```prefix``` instead of the child's attribute name:

``` ruby
class ParentPrefix < ParentBase
  validates :child, nested: { only: :attribute1, prefix: 'OMG'}
end

parent = ParentPrefix.new
parent.valid?
puts parent.errors.messages

 # => {:"OMG attribute1"=>["can't be blank"]}
```

### What happens if the child is an Array or Hash?

In this case, each value in the array or hash will be validated and the error message will
include the index or key of the value.

For an array:

``` ruby
class ParentArray < ParentBase
  validates :child, nested: { only: :attribute1 }
end

parent = ParentArray.new
parent.child = [Child.new] * 2
parent.valid?
puts parent.errors.messages

 # => {:"child[0] attribute1"=>["can't be blank"], :"child[1] attribute1"=>["can't be blank"]}
```

For a hash:

``` ruby
class ParentHash < ParentBase
  validates :child, nested: { only: :attribute1 }
end

parent = ParentHash.new
parent.child = { thing1: Child.new, thing2: Child.new }
parent.valid?
puts parent.errors.messages

 # => {:"child[thing1] attribute1"=>["can't be blank"], :"child[thing2] attribute1"=>["can't be blank"]}
```

### Can I easily use this for multiple child attributes?

You can use the ```validates_nested``` method:

``` ruby
class ParentMultiple < ParentBase
  attr_accessor :child2

  validates_nested :child, :child2, only: :attribute1

  def initialize
    self.child  = Child.new
    self.child2 = Child.new
  end
end

parent = ParentMultiple.new
parent.valid?
puts parent.errors.messages

 # => {:"child attribute1"=>["can't be blank"], :"child2 attribute1"=>["can't be blank"]}
```

## Testing With RSpec

When you ```require nested_validator``` you will have access to the RSpec matcher ```validate_nested```
that you can use in your specs.

Here are some examples:

``` ruby
describe Parent do
  it { should validate_nested(:child) }
  it { should validate_nested(:child).with_prefix(:thing1) }
  it { should validate_nested(:child).only(:attribute1) }
  it { should validate_nested(:child).only(:attribute1, :attribute2) }
  it { should validate_nested(:child).except(:attribute1) }
  it { should validate_nested(:child).except(:attribute1, :attribute2) }
end
```
## Contributing

1. Fork it ( https://github.com/dwhelan/nested_validator/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
