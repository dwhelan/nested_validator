require 'active_model'
require 'active_support/core_ext/array'

module ActiveModel
  module Validations
    class NestedValidator < EachValidator

      def validate_each(record, attribute, inputs)
        @attribute = attribute
        @values = Array.wrap(inputs)
        validate_each_input(record)
      end

      private

      attr_reader :attribute, :values

      def validate_each_input(record)
        values.each_with_index do |value, index|
          unless value.valid?
            value.errors.each do |key, error|
              record.errors.add(nested_key(key, index), error) if include?(key)
            end
          end
        end
      end

      def include_index?
        values.count > 1
      end

      def nested_key(key, index)
        "#{prefix(index)} #{key}".strip.to_sym
      end

      def prefix(index)
        prefix = (options.has_key?(:prefix) ? options[:prefix] : attribute).to_s
        prefix += "[#{index}]" if include_index?
        prefix
      end

      def include?(key)
        if options[:only]
          only.any?{|k| key =~ /^#{k}/}
        elsif options[:except]
          except.none?{|k| key =~ /^#{k}/}
        else
          true
        end
      end

      def only
        Array.wrap(options[:only])
      end

      def except
        Array.wrap(options[:except])
      end
    end

    module HelperMethods
      def self.validates_nested(*attr_names)
        validates_with NestedValidator, _merge_attributes(attr_names)
      end
    end
  end
end
