require_relative 'command_returning_hash'

module Mutations
  class CommandReturningArray < CommandReturningHash
    class << self
      def create_outcome_attr_methods(meth, &block)
        outcome_filters.send(meth, &block)
        keys = outcome_filters.send("#{meth}_keys")
        keys.each do |key|
          define_method("outcome_#{key}") { @outputs.map { |o| o[key] } }
          define_method("outcome_#{key}_present?") { @outputs.map { |o| o.key?(key) } }
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
    end

    def errors
      return nil unless errors?

      ErrorHash.new.tap do |h|
        h.merge! @errors if has_errors?

        case @outcome_errors
        when ErrorHash then h.merge! @outcome_errors
        when Hash
          h.merge!(@outcome_errors.each_with_object({}) do |(idx, err), memo|
            memo.merge! err[:errors].map { |k, v| [:"#{k}_#{idx}", v] }.to_h
          end)
        end
      end
    end

    def run
      return validation_outcome if has_errors?
      validation_outcome(
        execute.tap do |result|
          case result
          when Array
            result.each_with_index.with_object({}) do |(e, i), memo|
              _, outcome_error = self.class.outcome_filters.filter(e)
              outcome_error = validate_outcome(e) if outcome_error.nil?
              memo[i] = { outcome: e, errors: outcome_error } unless outcome_error.nil?
            end.tap do |errs|
              @outcome_errors = errs unless errs.empty?
            end
          when NilClass then nil
          else add_outcome_error :self, :type, "This mutation must return Array instance (was #{result.class})"
          end
        end
      )
    end

  protected

    def filtered result
      @outputs = result.is_a?(Array) && has_outcome_errors? ? result.reject.with_index { |_, i| @outcome_errors[i] } : result
    end
  end
end
