require 'active_model'
require 'active_support/core_ext/array'

module ActiveModel
  module Validations
    # Bases an object's validity on nested attributes.
    #
    # @see ActiveModel::Validations::HelperMethods#validates_nested validates_nested
    class NestedValidator < EachValidator

      private

      def validate_each(record, attribute, values)
        with_each_value(values) do |index, value|
          prefix = prefix(attribute, index, include_index?(values))
          record_error(record, prefix, value) if value.invalid?
        end
      end

      def with_each_value(values, &block)
        case values
          when Hash
            values.each { |key, value| block.call key, value }
          else
            Array.wrap(values).each_with_index { |value, index| block.call index, value}
        end
      end

      def include_index?(values)
        values.respond_to? :each
      end

      def prefix(attribute, index, include_index)
        prefix = (options.has_key?(:prefix) ? options[:prefix] : attribute).to_s
        prefix << "[#{index}]" if include_index
        prefix
      end

      def record_error(record, prefix, value)
        value.errors.each do |key, error|
          record.errors.add(nested_key(prefix, key), error) if include?(key)
        end
      end

      def nested_key(prefix, key)
        "#{prefix} #{key}".strip.to_sym
      end

      def include?(key)
        if only.present?
          only.include?(key.to_s)
        elsif except.present?
          !except.include?(key.to_s)
        else
          true
        end
      end

      def only
        @only ||= prepare_options(:only)
      end

      def except
        @except ||= prepare_options(:except)
      end

      def prepare_options(key)
        Array.wrap(options[key]).map(&:to_s).map{|k| k.split(/\s+|,/)}.reject(&:blank?).flatten
      end
    end

    module HelperMethods
      # Bases an object's validity on nested attributes.
      #
      #   class Parent < ActiveRecord::Base
      #     has_one :child
      #
      #     validates_nested :child
      #   end
      #
      #   class Child < ActiveRecord::Base
      #     attr_accessor :attribute
      #     validates     :attribute, presence: true
      #
      #     validates_presence_of :attribute
      #   end
      #
      # Any errors in the child will be copied to the parent using the child's name as
      # a prefix for the error:
      #
      #   puts parent.errors.messages #=> { :'child attribute' => ["can't be blank"] }
      #
      # @param attr_names attribute names followed with options
      #
      # @option attr_names [String] :prefix The prefix to use instead of the attribute name
      #
      # @option attr_names [String, Array] :only The name(s) of attr_names to include
      #   when validating. Default is <tt>all</tt>
      #
      # @option attr_names [String, Array] :except The name(s) of attr_names to exclude
      #   when validating. Default is <tt>none</tt>
      #
      # @option attr_names [Symbol] :on Specifies when this validation is active. Runs in all
      #   validation contexts by default (+nil+), other options are <tt>:create</tt>
      #   and <tt>:update</tt>.
      #
      # @option attr_names  [Symbol, String or Proc] :if a method, proc or string to call to determine
      #   if the validation should occur (e.g. <tt>if: :allow_validation</tt>,
      #   or <tt>if: Proc.new { |user| user.signup_step > 2 }</tt>). The method,
      #   proc or string should return or evaluate to a true or false value.
      #
      # @option attr_names [[Symbol, String or Proc]] :unless a method, proc or string to call to determine
      #   if the validation should not occur (e.g. <tt>unless: :skip_validation</tt>,
      #   or <tt>unless: Proc.new { |user| user.signup_step <= 2 }</tt>). The method,
      #   proc or string should return or evaluate to a true or false value.
      #
      # @option attr_names [boolean] :strict Specifies whether validation should be strict.
      #   See <tt>ActiveModel::Validation#validates!</tt> for more information.
      #
      # @see ActiveModel::Validations::NestedValidator

      def validates_nested(*attr_names)
        validates_with NestedValidator, _merge_attributes(attr_names)
      end
    end
  end
end
