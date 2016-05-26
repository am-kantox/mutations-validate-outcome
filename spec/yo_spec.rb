require 'spec_helper'

describe 'Extensions to Mutations' do
  class TestCommand < Mutations::Command
    def execute
      raise "¡I’m raised!"
    end
  end
  class TestCommandHash < Mutations::CommandReturningHash
    outcome_required { integer :a }
    def execute
      { a: 42 }
    end
  end
  class TestCommandArray < Mutations::CommandReturningArray
    outcome_required { integer :a }
    def execute
      [{ a: 42 }, { a: -1 }, { a: 0 }]
    end
  end

  S_EX = begin 0 / 0; rescue => e; e end
  V_EX = begin TestCommand.yo!; rescue => e; e end

  describe 'Mutations::YoValidationException' do
    it 'wraps the validation exception' do
      yo_s = Mutations::YoValidationException.new(S_EX)
      yo_v = Mutations::YoValidationException.new(V_EX)
      assert_equal yo_s.errors.keys, yo_v.errors.keys
      assert_equal yo_s.errors.values.map(&:class), yo_v.errors.values.map(&:class)
    end
    it 'has a meaningful error message' do
      yo_s = Mutations::YoValidationException.new(S_EX)
      yo_v = Mutations::YoValidationException.new(V_EX)
      assert_equal yo_s.message, 'error: “divided by 0”'
      assert_equal yo_v.message, 'error: “¡I’m raised!”'
      assert_equal yo_s.errors.symbolic, "error" => :ZeroDivisionError
      assert_equal yo_v.errors.symbolic, "error" => :RuntimeError
    end
  end

  describe 'Mutations::Command#yo' do
    it 'raises an exception when no block is given' do
      assert_raises Mutations::YoValidationException do
        TestCommand.yo!
      end
    end

    it 'raises an exception when a block is given and returns truthy' do
      assert_raises Mutations::YoValidationException do
        TestCommand.yo! { true }
      end
    end

    it 'has internals defined and raises no exception' do
      TestCommand.yo! do |ve|
        assert_equal ve.errors[:error].symbolic, :RuntimeError
        assert_equal ve.errors[:error].message, "¡I’m raised!"
        nil
      end
    end

    it 'returns Mashie::Hash on returned Hash if it is loaded' do
      assert_equal TestCommandHash.yo!.class, Hash
      assert_equal TestCommandHash.yo!.class, Hashie::Mash if (begin require 'hashie/mash'; rescue LoadError; nil end)
    end

    it 'returns an array of Mashie::Hashes on returned Array if it is loaded' do
      assert_equal TestCommandArray.yo!.map(&:class).first, Hash
      assert_equal TestCommandArray.yo!.map(&:class).first, Hashie::Mash if (begin require 'hashie/mash'; rescue LoadError; nil end)
    end
  end
end
