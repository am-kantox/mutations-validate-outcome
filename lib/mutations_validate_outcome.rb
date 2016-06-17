# require_relative 'mutations/additional_filter.rb'
# require 'mutations'

require_relative './mutations/version.rb'

require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/string/inflections'
require 'date'
require 'time'
require 'bigdecimal'

require 'mutations/exception'
require 'mutations/errors'
require 'mutations/input_filter'
require_relative './mutations/additional_filter'
require_relative './mutations/outcome_hash_filter.rb'
require 'mutations/string_filter'
require 'mutations/integer_filter'
require 'mutations/float_filter'
require 'mutations/boolean_filter'
require 'mutations/duck_filter'
require 'mutations/date_filter'
require 'mutations/file_filter'
# require 'mutations/time_filter'
require 'mutations/model_filter'
require 'mutations/array_filter'
require 'mutations/hash_filter'
require 'mutations/outcome_hash_filter'
require 'mutations/outcome'
require 'mutations/command'
require_relative './mutations/command_returning_hash.rb'
require_relative './mutations/command_returning_array.rb'

module Mutations
  class << self
    def error_message_creator
      @error_message_creator ||= DefaultErrorMessageCreator.new
    end

    def error_message_creator=(creator)
      @error_message_creator = creator
    end

    def cache_constants=(val)
      @cache_constants = val
    end

    def cache_constants?
      @cache_constants
    end
  end

  class ValidationException
    def inspect
      # rubocop:disable Style/FormatString
      oid = '%x' % (object_id << 1)
      "#<Mutations::ValidationException:0x#{oid.rjust(14, '0')} @errors=<#{errors}>>"
      # rubocop:enable Style/FormatString
    end

    def message
      errors.map do |k, v|
        "#{k}: “#{v.message || v.symbol}”"
      end.join(', ')
    end
  end

  class YoValidationException < ValidationException
    attr_reader :cause, :owner
    def initialize(e, owner = nil)
      super(e.is_a?(ValidationException) ? e.errors : Mutations::ErrorHash[error: Mutations::ErrorAtom.new(e.message.to_sym, e.class.name.to_sym, message: e.message)])
      @cause, @owner = e, owner || caller
    end
  end

  class Command
    class << self
      def input_descriptions
        input_filters.input_descriptions if input_filters.respond_to?(:input_descriptions)
      end

      def yo! *args
        result = run!(*args)
        case name # name of the class
        when ->(_) { !const_defined?('Hashie::Mash') } then result
        when /Hash\z/ then ::Hashie::Mash.new(result)
        when /Array\z/ then result.map { |h| ::Hashie::Mash.new(h) }
        else result
        end
      rescue => e
        yve = YoValidationException.new(e, self)
        # we’ll re-raise either if no block was given, or if the block returned truthy
        raise yve if !block_given? || (yield yve)
      end

      alias_method :required_input, :required
      alias_method :optional_input, :optional
    end
  end
end

Mutations.cache_constants = true
