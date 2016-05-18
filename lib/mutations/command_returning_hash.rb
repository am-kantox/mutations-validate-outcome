module Mutations
  class CommandReturningHash < Command
    class << self
      def create_outcome_attr_methods(meth, &block)
        outcome_filters.send(meth, &block)
        keys = outcome_filters.send("#{meth}_keys")
        keys.each do |key|
          define_method("outcome_#{key}") { @outputs[key] }
          define_method("outcome_#{key}_present?") { @outputs.key?(key) }
        end
      end
      private :create_outcome_attr_methods

      # %i(required optional).each do |m|
      #   meth = :"outcome_#{m}"
      #   define_method(meth) do |&block|
      #     create_outcome_attr_methods(meth, &block)
      #   end
      # end

      def outcome_required(&block)
        create_outcome_attr_methods(:outcome_required, &block)
      end

      def outcome_optional(&block)
        create_outcome_attr_methods(:outcome_optional, &block)
      end

      def outcome_filters
        @outcome_filters ||= (CommandReturningHash == superclass) ? OutcomeHashFilter.new : superclass.outcome_filters.dup
      end
    end

    def initialize(*args)
      super(*args)
      @outputs = {}
    end

    def outcome_filters
      self.class.outcome_filters
    end

    def has_outcome_errors?
      !@outcome_errors.nil?
    end

    def errors?
      has_errors? || has_outcome_errors?
    end

    def errors
      return nil unless errors?

      ErrorHash.new.tap do |h|
        h.merge! @errors if has_errors?
        h.merge! @outcome_errors if has_outcome_errors?
      end
    end

    def run
      return validation_outcome if has_errors?
      validation_outcome(
        execute.tap do |result|
          if result.is_a?(Hash)
            _, @outcome_errors = self.class.outcome_filters.filter(result)
            validate_outcome(result) unless has_outcome_errors?
          else
            add_outcome_error :self, :type, "This mutation must return Hash instance (was #{result.class})"
          end
        end
      )
    end

    def run!
      (outcome = run).success? ? outcome.result : (raise ValidationException.new(outcome.errors))
    end

    def validation_outcome(result = nil)
      Outcome.new(!errors?, filtered(result), errors, @inputs)
    end

  protected

    attr_reader :inputs, :raw_inputs, :outputs

    def validate_outcome outcome
      # Meant to be overridden
    end

    def filtered result
      @outputs = result.is_a?(Hash) && has_outcome_errors? ? result.reject { |k, _| @outcome_errors[k.to_sym] } : result
    end

    # add_outcome_error("name", :too_short)
    # add_outcome_error("colors.foreground", :not_a_color) # => to create errors = {colors: {foreground: :not_a_color}}
    # or, supply a custom message:
    # add_outcome_error("name", :too_short, "The name 'blahblahblah' is too short!")
    def add_outcome_error(key, kind, message = nil)
      raise ArgumentError.new("Invalid kind") unless kind.is_a?(Symbol)

      @outcome_errors ||= ErrorHash.new
      @outcome_errors.tap do |errs|
        path = key.to_s.split(".")
        last = path.pop
        inner = path.inject(errs) do |cur_errors, part|
          cur_errors[part.to_sym] ||= ErrorHash.new
        end
        inner[last] = ErrorAtom.new(key, kind, message: message)
      end
    end

    def merge_outcome_errors(hash)
      (@outcome_errors ||= ErrorHash.new).tap do |errs|
        errs.merge!(hash) if hash.any?
      end
    end
  end
end
