require 'minitest'
require 'minitest/unit'
require 'minitest/autorun'
require 'minitest/color'
require 'minitest/documentation'
require 'pry'

require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start

require 'mutations_validate_outcome'

$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__) + '/../lib')
