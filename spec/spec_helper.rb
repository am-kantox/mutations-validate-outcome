require 'minitest'
require 'minitest/unit'
require 'minitest/autorun'
require 'minitest/color'
require 'minitest/documentation'
require 'pry'

require_relative 'spec_sqlite_helper'

require 'simplecov'
SimpleCov.start

require 'mutations_validate_outcome'

$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__) + '/../lib')
