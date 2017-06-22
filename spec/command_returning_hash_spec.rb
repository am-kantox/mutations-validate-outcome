require 'spec_helper'
require 'simple_command_returning_hash'

describe 'CommandReturningHash' do

  describe "SimpleCommandReturningHash" do
    it "should allow valid output" do
      outcome = SimpleCommandReturningHash.run(name: "John", email: "john@gmail.com", amount: 5)

      assert outcome.success?
      assert_equal({ name: "John", email: "john@gmail.com", amount: 5 }.stringify_keys, outcome.result)
      assert_equal nil, outcome.errors
    end

    it "should reject invalid output by filters" do
      outcome = SimpleCommandReturningHash.run(name: "JohnnyCash", email: "john@gmail.com", amount: 5)

      assert !outcome.success?
      assert_equal :max_length, outcome.errors.symbolic[:name]
    end

    it "should reject invalid output by handler" do
      outcome = SimpleCommandReturningHash.run(name: "Jimmy", email: "john@gmail.com", amount: 5)

      assert !outcome.success?
      assert_equal :invalid, outcome.errors.symbolic[:name]
    end

    it "should return filtered result on outcome error" do
      outcome = SimpleCommandReturningHash.run(name: "JohnnyCash", email: "john@gmail.com", amount: 5)

      assert !outcome.success?
      assert_equal :max_length, outcome.errors.symbolic[:name]
      assert([Hash, ActiveSupport::HashWithIndifferentAccess].any? { |c| outcome.result.is_a? c  })
      assert_equal 2, outcome.result.length
      assert_equal nil, outcome.result['name']
    end

    it "should not add any errors on nil outcome" do
      class CommandReturningNilHash < Mutations::CommandReturningHash

        required { string :name }
        optional { string :email }

        outcome_required { string :name }

        def execute
          nil
        end
      end
      outcome = CommandReturningNilHash.run

      assert !outcome.success?
      assert outcome.result.nil?
      assert_equal 1, outcome.errors.count
      assert !outcome.errors.key?(:self)
    end

    it "shouldn't throw an exception with run!" do
      result = SimpleCommandReturningHash.run!(name: "John", email: "john@gmail.com", amount: 5)
      assert_equal({ name: "John", email: "john@gmail.com", amount: 5 }.stringify_keys, result)
    end

    it "should throw an exception with run!" do
      assert_raises Mutations::ValidationException do
        SimpleCommandReturningHash.run!(name: "Jimmy", email: "john@gmail.com")
      end
    end

    it "shouldn't accept non-hashes as output" do
      class CommandNotReturningHash < Mutations::CommandReturningHash
        def execute
          42
        end
      end

      outcome = CommandNotReturningHash.run
      assert !outcome.success?
      assert_equal :type, outcome.errors.symbolic[:self]
      assert_equal "This mutation must return Hash instance (was Fixnum)", outcome.errors.message[:self]

      assert_raises Mutations::ValidationException do
        CommandNotReturningHash.run!
      end
    end

    describe "EigenCommandReturningHash" do
      class EigenCommandReturningHash < Mutations::CommandReturningHash

        required { string :name }
        optional { string :email }

        outcome_required { string :name }

        def execute
          { name: name, email: email }
        end
      end

      it "should define getter methods on params" do
        mutation = EigenCommandReturningHash.new(name: "John", email: "john@gmail.com")
        mutation.run
        assert_equal "John", mutation.outcome_name
      end
    end

    describe "PresentCommandReturningHash" do
      class PresentCommandReturningHash < Mutations::CommandReturningHash

        required do
          integer :choice
        end

        outcome_optional do
          string :email
          string :name
        end

        def execute
          case inputs[:choice]
          when 1 then { name: 'John' }
          when 2 then { email: 'john@gmail.com' }
          when 3 then { name: 'John', email: 'john@gmail.com' }
          else { }
          end
        end
      end

      it "should handle outcome_*_present? methods" do
        muts = [0, 1, 2, 3].map { |i| PresentCommandReturningHash.new(choice: i).tap(&:run) }

        assert !muts[0].outcome_name_present?
        assert !muts[0].outcome_email_present?
        assert muts[1].outcome_name_present?
        assert !muts[1].outcome_email_present?
        assert !muts[2].outcome_name_present?
        assert muts[2].outcome_email_present?
        assert muts[3].outcome_name_present?
        assert muts[3].outcome_email_present?
      end
    end
  end
end
