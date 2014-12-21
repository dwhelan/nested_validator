require 'active_model'
require 'active_support/core_ext/array'

module ActiveModel
  module Validations
    class NestedValidator < EachValidator

      def validate_each(record, attribute, values)
        values = Array.wrap(values)
        include_index = values.count > 1

        values.each_with_index do |value, index|
          record_error(record, value, attribute, include_index, index) if value.invalid?
        end
      end

      def record_error(record, value, attribute, include_index, index)
        value.errors.each do |key, error|
          nested_key = nested_key(key, index, attribute, include_index)
          record.errors.add(nested_key, error) if include?(key)
        end
      end

      private

      def prefix(index, attribute, include_index)
        prefix = (options.has_key?(:prefix) ? options[:prefix] : attribute).to_s
        prefix += "[#{index}]" if include_index
        prefix
      end

      def nested_key(key, index, attribute, include_index)
        "#{prefix(index, attribute, include_index)} #{key}".strip.to_sym
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
      def validates_nested(*attr_names)
        validates_with NestedValidator, _merge_attributes(attr_names)
      end
    end
  end
end
