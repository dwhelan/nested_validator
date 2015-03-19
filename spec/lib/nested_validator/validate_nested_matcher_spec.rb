require_relative 'nested_validator_context'

describe 'validates_nested with [parent class with "validates, child]"' do

  include_context 'nested validator'

  let(:parent)    { parent_class.new child_class.new }
  let(:options)   { { nested: true } }
  let(:validator) { instance_eval self.class.description }

  describe 'its validations with options:' do
    let(:options) { self.class.description }

    subject { parent }

    context 'true' do
      it { should validate_nested(:child) }
      it { should validate_nested('child') }

      it { should_not validate_nested(:child2) }
      it { should_not validate_nested(:invalid_child_name) }
    end

    context '{prefix: "OMG"}' do
      it { should validate_nested(:child).with_prefix('OMG') }
      it { should validate_nested(:child).with_prefix(:OMG) }

      it { should_not validate_nested(:child) }
      it { should_not validate_nested(:child).with_prefix('WTF') }
      it { should_not validate_nested(:child).with_prefix(:WTF) }
    end

    context '{only: :attribute}' do
      it { should validate_nested(:child).only(:attribute) }
      it { should validate_nested(:child).only('attribute') }

      it { should_not validate_nested(:child).only(:attribute2) }
      it { should_not validate_nested(:child).only('attribute2') }
      it { should_not validate_nested(:child).only(:invalid_attribute_name) }
      it { should_not validate_nested(:child).only(:attribute, :attribute2) }
    end

    context '{only: [:attribute, :attribute2]}' do
      it { should validate_nested(:child).only(:attribute) }
      it { should validate_nested(:child).only(:attribute2) }
      it { should validate_nested(:child).only(:attribute,  :attribute2) }
      it { should validate_nested(:child).only('attribute', 'attribute2') }
      it { should validate_nested(:child).only('attribute,   attribute2') }

      it { should_not validate_nested(:child).only(:attribute2, :attribute3) }
      it { should_not validate_nested(:child).only(:invalid_attribute_name) }
    end

    context '{except: :attribute}' do
      it { should validate_nested(:child).except(:attribute) }
      it { should validate_nested(:child).except('attribute') }

      it { should_not validate_nested(:child).except(:attribute2) }
    end

    context '{except: [:attribute, :attribute2]}' do
      it { should validate_nested(:child).except(:attribute, :attribute2) }
    end

    context '{any: :attribute}' do
      it { should validate_nested(:child).any(:attribute) }
      it { should validate_nested(:child).any('attribute') }

      it { should_not validate_nested(:child).any(:attribute2) }
      it { should_not validate_nested(:child).any('attribute2') }
    end
  end

  describe 'its description for:' do
    subject { validator.description }

    context('validate_nested(:child)')                    { it { should eq 'validate nested :child' } }
    context('validate_nested(:child).only(:attribute)')   { it { should eq 'validate nested :child with only: :attribute' } }
    context('validate_nested(:child).except(:attribute)') { it { should eq 'validate nested :child except: :attribute' } }
    context('validate_nested(:child).any(:attribute)')    { it { should eq 'validate nested :child any: :attribute' } }
    context('validate_nested(:child).with_prefix(:OMG)')  { it { should eq 'validate nested :child with prefix :OMG' } }
  end

  describe 'its error messages:' do
    let(:options)      { self.class.parent.description }
    let(:expect_match) { false }

    before { expect(validator.matches? parent).to be expect_match }

    describe 'common failure messages' do
      [:failure_message, :failure_message_when_negated].each do |message|
        subject { validator.send message }

        context 'true' do
          describe('validate_nested(:invalid_child_name)')                    { it { should eq "parent doesn't respond to :invalid_child_name" } }
          describe('validate_nested(:child).only(:invalid_attribute_name)')   { it { should eq "child doesn't respond to :invalid_attribute_name" } }
          describe('validate_nested(:child).except(:invalid_attribute_name)') { it { should eq "child doesn't respond to :invalid_attribute_name"  } }
        end
      end
    end

    describe 'failure_message' do
      subject { validator.failure_message }

      context 'true' do
        describe('validate_nested(:other)') { it { should eq "parent doesn't nest validations for :other" } }
      end

      context '{prefix: :OMG}' do
        describe('validate_nested(:child)')                   { it { should eq "parent has a prefix of :OMG. Are you missing '.with_prefix(:OMG)'?" } }
        describe('validate_nested(:child).with_prefix(:WTF)') { it { should eq 'parent uses a prefix of :OMG rather than :WTF' } }
      end

      context '{only: :attribute}' do
        describe('validate_nested(:child).only(:attribute2)')             { it { should eq "parent doesn't nest validations for: :attribute2"  } }
        describe('validate_nested(:child).only(:attribute, :attribute2)') { it { should eq "parent doesn't nest validations for: :attribute2"  } }
      end

      context '{except: :attribute}' do
        describe('validate_nested(:child).except(:attribute2)')             { it { should eq 'parent does nest validations for: :attribute2' } }
        describe('validate_nested(:child).except(:attribute, :attribute2)') { it { should eq 'parent does nest validations for: :attribute2' } }
      end

      context '{any: :attribute}' do
        describe('validate_nested(:child).any(:attribute2)')             { it { should eq "parent doesn't nest validations for: :attribute2"  } }
        describe('validate_nested(:child).any(:attribute, :attribute2)') { it { should eq "parent doesn't nest validations for: :attribute2"  } }
      end
    end

    describe 'failure_message_when_negated' do
      let(:expect_match) { true }

      subject { validator.failure_message_when_negated }

      context 'true' do
        describe('validate_nested(:child)') { it { should eq 'parent does nest validations for: :child' } }
      end

      context '{prefix: :OMG}' do
        describe('validate_nested(:child).with_prefix(:OMG)') { it { should eq 'parent does nest validations for: :child with a prefix of :OMG' } }
      end

      context '{only: :attribute}' do
        describe('validate_nested(:child).only(:attribute)') { it { should eq 'parent does nest :child validations for: :attribute' } }
      end

      context '{only: [:attribute, :attribute2]}' do
        describe('validate_nested(:child).only(:attribute)')              { it { should eq 'parent does nest :child validations for: :attribute' } }
        describe('validate_nested(:child).only(:attribute, :attribute2)') { it { should eq 'parent does nest :child validations for: :attribute, :attribute2' } }
      end

      context '{except: :attribute}' do
        describe('validate_nested(:child).except(:attribute)') { it { should eq "parent doesn't nest :child validations for: :attribute" } }
      end

      context '{except: [:attribute, :attribute2]}' do
        describe('validate_nested(:child).except(:attribute)')              { it { should eq "parent doesn't nest :child validations for: :attribute" } }
        describe('validate_nested(:child).except(:attribute, :attribute2)') { it { should eq "parent doesn't nest :child validations for: :attribute, :attribute2" } }
      end
    end
  end
end
