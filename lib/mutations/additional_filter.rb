require 'mutations/hash_filter'
require 'mutations/outcome_hash_filter'
require 'mutations/array_filter'

module Mutations
  class HashFilter < InputFilter
    attr_accessor :input_descriptions, :input_description

    def desc input_description
      @input_description = input_description
    end

    def current_input_description
      (@input_description && @input_description.dup).tap do
        @input_description = nil
      end
    end

    def self.register_additional_filter(type_class, type_name)
      define_method(type_name) do |*args, &block|
        name = args[0]
        options = args[1] || {}
        # rubocop:disable Lint/AssignmentInCondition
        if described = current_input_description
          (@input_descriptions ||= {})[name.to_sym] = described
        end
        # rubocop:enable Lint/AssignmentInCondition
        @current_inputs[name.to_sym] = type_class.new(options, &block)
      end
    end
  end

  class AdditionalFilter < InputFilter
    def self.inherited(subclass)
      type_name = subclass.name[/^Mutations::([a-zA-Z]*)Filter$/, 1].underscore

      Mutations::HashFilter.register_additional_filter(subclass, type_name)
      Mutations::OutcomeHashFilter.register_additional_filter(subclass, type_name)
      Mutations::ArrayFilter.register_additional_filter(subclass, type_name)
    end
  end
end
