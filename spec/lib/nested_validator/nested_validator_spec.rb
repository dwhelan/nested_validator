require 'spec_helper'
require 'nested_validator'

RSpec::Matchers.define :detect_nested_error_for do
  match do
    subject.valid?
    error.present?
  end

  def description
    "detect an error for '#{child_attribute}'"
  end

  failure_message do
    "has no error for '#{child_attribute}'"
  end

  failure_message_when_negated do
    "has an error '#{child_attribute}' => '#{error}'"
  end

  def error
    subject.errors[child_attribute].first
  end

  def attribute
    expected
  end

  def attribute_display_value
    "#{subject.child.send(attribute) || 'nil'}"
  end

  def child_attribute
    :"child #{attribute}"
  end
end

module Test

  class Base
    include ActiveModel::Validations

    def self.model_name
      ActiveModel::Name.new(self, nil, 'temp')
    end
  end

  class Parent < Base
    attr_accessor :child

    def initialize(child=nil)
      self.child = child
    end
  end

  class Child < Base
    attr_accessor :attribute
    validates     :attribute, presence: true

    attr_accessor :attribute2
    validates     :attribute2, presence: true

    attr_accessor :attribute3
    validates     :attribute3, presence: true
  end

  describe 'nested validation' do

    let(:parent_class) do
      opts = options
      Class.new(Parent) { instance_eval "validates :child, nested: #{opts}" }
    end

    let(:options) { 'true' }
    let(:parent) { parent_class.new child }
    let(:child) { Child.new }

    before { parent.valid? }
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

    describe 'error message keys' do
      subject { parent.errors.messages.keys.first }

      context('true')            { it { should eq :'child attribute' } }
      context('{prefix: ""}')    { it { should eq :'attribute' } }
      context('{prefix: nil}')   { it { should eq :'attribute' } }
      context('{prefix: "OMG"}') { it { should eq :'OMG attribute' } }

      context 'with arrays' do
        let(:child) { [Child.new] }

        context('true')            { it { should eq :'child[0] attribute' } }
        context('{prefix: ""}')    { it { should eq :'[0] attribute' } }
        context('{prefix: nil}')   { it { should eq :'[0] attribute' } }
        context('{prefix: "OMG"}') { it { should eq :'OMG[0] attribute' } }
      end

      context('with hashes') do
        let(:child) { {key: Child.new} }

        context('true')            { it { should eq :'child[key] attribute' } }
        context('{prefix: ""}')    { it { should eq :'[key] attribute' } }
        context('{prefix: nil}')   { it { should eq :'[key] attribute' } }
        context('{prefix: "OMG"}') { it { should eq :'OMG[key] attribute' } }
      end
    end
  end
end
