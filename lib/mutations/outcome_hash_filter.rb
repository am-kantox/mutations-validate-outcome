module Mutations
  class OutcomeHashFilter < InputFilter
    def self.register_additional_filter(type_class, type_name)
      define_method(type_name) do |*args, &block|
        name = args[0]
        options = args[1] || {}

        @outcome_descriptions[name.to_sym] = current_outcome_description || 'N/A'

        @current_outputs[name.to_sym] = type_class.new(options, &block)
      end
    end

    @default_options = {
      nils: false
    }

    attr_accessor :optional_outputs, :required_outputs, :outcome_descriptions, :outcome_description

    def initialize(opts = {}, &block)
      super(opts)

      @optional_outputs = {}
      @current_outputs = @required_outputs = {}

      instance_eval(&block) if block_given?
    end

    def dup
      dupped = OutcomeHashFilter.new
      @optional_outputs.each_pair do |k, v|
        dupped.optional_outputs[k] = v
      end
      @required_outputs.each_pair do |k, v|
        dupped.required_outputs[k] = v
      end
      dupped
    end

    def desc(outcome_description)
      @outcome_description = outcome_description
    end

    def current_outcome_description
      (@outcome_description && @outcome_description.dup).tap do
        @outcome_description = nil
      end
    end

    def outcome_required(&block)
      @current_outputs = @required_outputs
      instance_eval(&block)
    end

    def outcome_optional(&block)
      @current_outputs = @optional_outputs
      instance_eval(&block)
    end

    def outcome_required_keys
      @required_outputs.keys
    end

    def outcome_optional_keys
      @optional_outputs.keys
    end

    def hash(name, options = {}, &block)
      @current_outputs[name.to_sym] = OutcomeHashFilter.new(options, &block)
    end

    def model(name, options = {})
      @current_outputs[name.to_sym] = ModelFilter.new(name.to_sym, options)
    end

    def array(name, options = {}, &block)
      name_sym = name.to_sym
      @current_outputs[name.to_sym] = ArrayFilter.new(name_sym, options, &block)
    end

    def filter(data)
      # Handle nil case
      return (options[:nils] ? [nil, nil] : [nil, :nils]) if data.nil?

      # Ensure it's a hash
      return [data, :hash] unless data.is_a?(Hash)

      # We always want a hash with indiffernet access
      data = data.with_indifferent_access unless data.is_a?(HashWithIndifferentAccess)

      errors = ErrorHash.new
      filtered_data = HashWithIndifferentAccess.new
      wildcard_filterer = nil

      [[@required_outputs, true], [@optional_outputs, false]].each do |(outputs, is_required)|
        outputs.each_pair do |key, filterer|
          # If we are doing wildcards, then record so and move on
          if key == :*
            wildcard_filterer = filterer
            next
          end

          data_element = data[key]

          if data.key?(key)
            sub_data, sub_error = filterer.filter(data_element)

            case
            when sub_error.nil? then filtered_data[key] = sub_data
            when !is_required && filterer.discard_invalid? then data.delete(key)
            when !is_required && sub_error == :empty && filterer.discard_empty? then data.delete(key)
            when !is_required && sub_error == :nils && filterer.discard_nils? then data.delete(key)
            else
              sub_error = ErrorAtom.new(key, sub_error) if sub_error.is_a?(Symbol)
              errors[key] = sub_error
            end
            next
          end

          if filterer.has_default?
            filtered_data[key] = filterer.default
          elsif is_required
            errors[key] = ErrorAtom.new(key, :required)
          end
        end
      end

      if wildcard_filterer
        filtered_keys = data.keys - filtered_data.keys

        filtered_keys.each do |key|
          data_element = data[key]

          sub_data, sub_error = wildcard_filterer.filter(data_element)
          case
          when sub_error.nil? then filtered_data[key] = sub_data
          when wildcard_filterer.discard_invalid? then data.delete(key)
          when sub_error == :empty && wildcard_filterer.discard_empty? then data.delete(key)
          when sub_error == :nils && wildcard_filterer.discard_nils? then data.delete(key)
          else
            sub_error = ErrorAtom.new(key, sub_error) if sub_error.is_a?(Symbol)
            errors[key] = sub_error
          end
        end
      end

      errors.any? ? [data, errors] : [filtered_data, nil]
    end
  end
end
