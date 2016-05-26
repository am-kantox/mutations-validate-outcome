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
end

Mutations.cache_constants = true
