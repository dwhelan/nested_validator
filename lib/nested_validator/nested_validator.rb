require 'active_model'
require 'active_support/core_ext/array'

module ActiveModel
  module Validations
    class NestedValidator < EachValidator

      private

      def validate_each(record, attribute, values)
        values = Array.wrap(values)
        include_index = values.count > 1

        values.each_with_index do |value, index|
          prefix = prefix(attribute, index, include_index)
          record_error(record, prefix, value) if value.invalid?
        end
      end

      def record_error(record, prefix, value)
        value.errors.each do |key, error|
          record.errors.add(nested_key(prefix, key), error) if include?(key)
        end
      end

      def prefix(attribute, index, include_index)
        prefix = (options.has_key?(:prefix) ? options[:prefix] : attribute).to_s
        prefix << "[#{index}]" if include_index
        prefix
      end

      def nested_key(prefix, key)
        "#{prefix} #{key}".strip.to_sym
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
        @only ||= Array.wrap(options[:only])
      end

      def except
        @except ||= Array.wrap(options[:except])
      end
    end

    module HelperMethods
      def validates_nested(*attributes)
        validates_with NestedValidator, _merge_attributes(attributes)
      end
    end
  end
end
