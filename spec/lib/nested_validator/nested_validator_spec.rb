require_relative 'nested_validator_context'

RSpec::Matchers.define :detect_nested_error_for do
  match do
    subject.valid?
    error.present?
  end

  def description
    "detect an error for child '#{child_attribute}'"
  end

  failure_message do
    "has no error for child '#{child_attribute}'"
  end

  failure_message_when_negated do
    "has an error child '#{child_attribute}' => '#{error}'"
  end

  def error
    subject.errors[:child].find{|e| e =~ /^#{expected} /}
  end

  def attribute
    expected
  end

  def attribute_display_value
    "#{subject.child.send(attribute) || 'nil'}"
  end

  def child_attribute
    :"#{attribute}"
  end
end

describe 'nested validation' do

  include_context 'nested validator'

  let(:options) { 'true' }
  let(:parent)  { parent_class.new child }
  let(:child)   { child_class.new }

  subject { parent }

  let(:options) { self.class.description }

  describe 'should support boolean value' do
    describe 'true' do
      it { should detect_nested_error_for :attribute }
    end

    describe 'false' do
      it { should_not detect_nested_error_for :attribute }
    end
  end

  describe '"only" should be ignored if value missing' do
    ['{only: ""}',
     '{only: nil}',
    ].each do |only|
      describe only do
        it { should detect_nested_error_for :attribute }
        it { should detect_nested_error_for :attribute2 }
        it { should detect_nested_error_for :attribute3 }
      end
    end
  end

  describe '"only" should support a single key' do
    ['{only: :attribute}',
     '{only: "attribute"}',
     '{only: " \tattribute\t\n"}'
    ].each do |only|
      describe only do
        it { should     detect_nested_error_for :attribute }
        it { should_not detect_nested_error_for :attribute2 }
        it { should_not detect_nested_error_for :attribute3 }
      end
    end
  end

  describe '"only" should support multiple keys' do
    ['{only: [:attribute, :attribute2]}',
     '{only: "attribute attribute2"}',
     '{only: "attribute, attribute2"}',
     '{only: " \tattribute,\n\tattribute2\t\n"}'
    ].each do |only|
      describe only do
        it { should     detect_nested_error_for :attribute }
        it { should     detect_nested_error_for :attribute2 }
        it { should_not detect_nested_error_for :attribute3 }
      end
    end
  end

  describe '"except" should be ignored if value missing' do
    ['{except: ""}',
     '{except: nil}',
    ].each do |only|
      describe only do
        it { should detect_nested_error_for :attribute }
        it { should detect_nested_error_for :attribute2 }
        it { should detect_nested_error_for :attribute3 }
      end
    end
  end

  describe '"except" should support a single key' do
    ['{except: :attribute}',
     '{except: "attribute"}',
     '{except: " \tattribute\t\n"}'
    ].each do |only|
      describe only do
        it { should_not detect_nested_error_for :attribute }
        it { should     detect_nested_error_for :attribute2 }
        it { should     detect_nested_error_for :attribute2 }
      end
    end
  end

  describe '"except" should support multiple keys' do
    ['{except: [:attribute, :attribute2]}',
     '{except: "attribute attribute2"}',
     '{except: "attribute, attribute2"}',
     '{except: " \tattribute,\n\tattribute2\t\n"}'
    ].each do |only|
      describe only do
        it { should_not detect_nested_error_for :attribute }
        it { should_not detect_nested_error_for :attribute2 }
        it { should     detect_nested_error_for :attribute3 }
      end
    end
  end

  describe '"any" should be ignored if value missing' do
    ['{any: ""}',
     '{any: nil}',
    ].each do |only|
      describe only do
        it { should detect_nested_error_for :attribute }
        it { should detect_nested_error_for :attribute2 }
        it { should detect_nested_error_for :attribute3 }
      end
    end
  end

  describe '"any" should behave like "only" with a single key' do
    [
     '{any: :attribute}',
     '{any: "attribute"}',
     '{any: " \tattribute\t\n"}'
    ].each do |only|
      describe only do
        it { should     detect_nested_error_for :attribute }
        it { should_not detect_nested_error_for :attribute2 }
        it { should_not detect_nested_error_for :attribute3 }
      end
    end
  end

  describe '"any" should not detect errors if first attribute valid' do
    before { child.attribute = true }

    ['{any: [:attribute, :attribute2]}',
     '{any: "attribute attribute2"}',
     '{any: "attribute, attribute2"}',
     '{any: " \tattribute,\n\tattribute2\t\n"}'
    ].each do |only|
      describe only do
        it { should_not detect_nested_error_for :attribute }
        it { should_not detect_nested_error_for :attribute2 }
        it { should_not detect_nested_error_for :attribute3 }
      end
    end
  end

  describe '"any" should not detect errors if second attribute valid' do
    before { child.attribute2 = true }

    ['{any: [:attribute, :attribute2]}',
     '{any: "attribute attribute2"}',
     '{any: "attribute, attribute2"}',
     '{any: " \tattribute,\n\tattribute2\t\n"}'
    ].each do |only|
      describe only do
        it { should_not detect_nested_error_for :attribute }
        it { should_not detect_nested_error_for :attribute2 }
        it { should_not detect_nested_error_for :attribute3 }
      end
    end
  end

  describe 'error keys' do
    before { parent.valid? }
    subject { parent.errors.messages.keys.first }

    context('true')            { it { should eq :'child' } }
    context('{prefix: ""}')    { it { should eq :'' } }
    context('{prefix: nil}')   { it { should eq :'' } }
    context('{prefix: "OMG"}') { it { should eq :'OMG' } }

    context 'with arrays' do
      let(:child) { [child_class.new] }

      context('true')            { it { should eq :'child[0]' } }
      context('{prefix: ""}')    { it { should eq :'[0]' } }
      context('{prefix: nil}')   { it { should eq :'[0]' } }
      context('{prefix: "OMG"}') { it { should eq :'OMG[0]' } }
    end

    context('with hashes') do
      let(:child) { {key: child_class.new} }

      context('true')            { it { should eq :'child[key]' } }
      context('{prefix: ""}')    { it { should eq :'[key]' } }
      context('{prefix: nil}')   { it { should eq :'[key]' } }
      context('{prefix: "OMG"}') { it { should eq :'OMG[key]' } }
    end
  end

  describe 'error messages' do
    before { parent.valid? }
    subject { parent.errors.messages.values.first }

    context('true') do
      it { should include "attribute can't be blank" }
      it { should include "attribute2 can't be blank" }
      it { should include "attribute3 can't be blank" }
    end
  end

  describe 'multiple levels' do
    let(:grand_parent_class) do
      opts = parent_options
      Class.new {
        include ActiveModel::Validations

        attr_accessor :parent

        instance_eval "validates :parent, nested: #{opts}"

        def initialize(parent=nil)
          self.parent = parent
        end

        def to_s
          'grand_parent'
        end
      }
    end

    let(:grand_parent)   { grand_parent_class.new parent }
    let(:parent_options) { self.class.description }
    let(:options)        { 'true' }

    [
      '{only:   :other}',
      '{any:    :other}',
      '{except: :child}'
    ].each do |parent_options|
      describe parent_options do
        it { expect(grand_parent).to be_valid }
      end
    end

    [
      'true',
      '{only:   :child}',
      '{any:    :child}',
      '{except: :other}'
    ].each do |parent_options|
      describe parent_options do
        it { expect(grand_parent).to_not be_valid }
      end
    end

    describe 'errors[:parent]' do
      let(:parent_options) { true}

      before { grand_parent.valid? }
      subject { grand_parent.errors[:parent] }

      it { should include "child attribute can't be blank"  }
      it { should include "child attribute2 can't be blank" }
      it { should include "child attribute3 can't be blank" }
    end
  end
end
