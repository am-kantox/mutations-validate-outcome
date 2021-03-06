require 'spec_helper'
require 'simple_command_returning_array'

describe 'CommandReturningArray' do

  describe "SimpleCommandReturningArray" do
    it "provide the input descriptions via introspection" do
      assert_equal(
        SimpleCommandReturningArray.input_descriptions,
        name: "The name of length not more than 10 symbols", email: "The email", amount: "The amount"
      )
    end

    it "provide the output descriptions via introspection" do
      assert_equal(
        SimpleCommandReturningArray.output_descriptions,
        name: "The name of length not more than 5 symbols", email: "N/A", amount: "The amount"
      )
    end

    it "should allow valid output" do
      outcome = SimpleCommandReturningArray.run(name: "John", email: "john@gmail.com", amount: 5)
      assert outcome.success?
      assert_equal({ name: "John", email: "john@gmail.com", amount: 5 }.stringify_keys, outcome.result.first)
      assert_equal({ name: "John", email: "aleksei@gmail.com" }.stringify_keys, outcome.result.last)
      assert_equal nil, outcome.errors
    end

    it "should reject invalid output by filters" do
      outcome = SimpleCommandReturningArray.run(name: "JohnnyCash", email: "john@gmail.com", amount: 5)

      assert !outcome.success?
      assert_equal :max_length, outcome.errors.symbolic[:name_0]
    end

    it "should reject invalid output by handler" do
      outcome = SimpleCommandReturningArray.run(name: "Jimmy", email: "john@gmail.com", amount: 5)

      assert !outcome.success?
      assert_equal :invalid, outcome.errors.symbolic[:name_0]
    end

    it "should return filtered result on outcome error" do
      outcome = SimpleCommandReturningArray.run(name: "JohnnyCash", email: "john@gmail.com", amount: 5)

      assert !outcome.success?
      assert_equal :max_length, outcome.errors.symbolic[:name_0]
      assert outcome.result.is_a? Array
      assert_equal 1, outcome.result.length
      assert_equal 'John', outcome.result.first['name']
    end

    it "should not add any errors on nil outcome" do
      class CommandReturningNilArray < Mutations::CommandReturningArray

        required { string :name }
        optional { string :email }

        outcome_required { string :name }

        def execute
          nil
        end
      end
      outcome = CommandReturningNilArray.run

      assert !outcome.success?
      assert outcome.result.nil?
      assert_equal 1, outcome.errors.count
      assert !outcome.errors.key?(:self)
    end

    it "shouldn't throw an exception with run!" do
      result = SimpleCommandReturningArray.run!(name: "John", email: "john@gmail.com", amount: 5)
      assert_equal([
                     { name: "John", email: "john@gmail.com", amount: 5 }.stringify_keys,
                     { name: "John", email: "aleksei@gmail.com" }.stringify_keys
                   ], result)
    end

    it "should throw an exception with run!" do
      assert_raises Mutations::ValidationException do
        SimpleCommandReturningArray.run!(name: "Jimmy", email: "john@gmail.com")
      end
    end

    it "shouldn't accept non-arrays as output" do
      class CommandNotReturningArray < Mutations::CommandReturningArray
        def execute
          42
        end
      end

      outcome = CommandNotReturningArray.run
      assert !outcome.success?
      assert_equal :type, outcome.errors.symbolic[:self]
      assert_equal "This mutation must return Array instance (was Fixnum)", outcome.errors.message[:self]

      assert_raises Mutations::ValidationException do
        CommandNotReturningArray.run!
      end
    end

    describe "EigenCommandReturningArray" do
      class EigenCommandReturningArray < Mutations::CommandReturningArray

        required { string :name }
        optional { string :email }

        outcome_required { string :name }

        def execute
          [{ name: name, email: email }]
        end
      end

      it "should define getter methods on params" do
        mutation = EigenCommandReturningArray.new(name: "John", email: "john@gmail.com")
        mutation.run
        assert_equal ["John"], mutation.outcome_name
      end
    end

    describe "standardized aliases for input and output" do
      class AliasedCommandReturningArray < Mutations::CommandReturningArray

        required_input { string :name }
        optional_input { string :email }

        required_output { string :name }
        optional_output { string :email }

        def execute
          [{ name: name, email: email }]
        end
      end

      it "should define getter methods on params" do
        mutation = EigenCommandReturningArray.new(name: "John", email: "john@gmail.com")
        mutation.run
        assert_equal ["John"], mutation.outcome_name
      end
    end

    describe "PresentCommandReturningArray" do
      class PresentCommandReturningArray < Mutations::CommandReturningArray

        required do
          integer :choice
        end

        outcome_optional do
          string :email
          string :name
        end

        def execute
          case inputs[:choice]
          when 1 then [{ name: 'John' }]
          when 2 then [{ email: 'john@gmail.com' }]
          when 3 then [{ name: 'John', email: 'john@gmail.com' }]
          else { }
          end
        end
      end

      it "should handle outcome_*_present? methods" do
        muts = [0, 1, 2, 3].map { |i| PresentCommandReturningArray.new(choice: i).tap(&:run) }

        assert !muts[0].outcome_name_present?[0]
        assert !muts[0].outcome_email_present?[0]
        assert muts[1].outcome_name_present?[0]
        assert !muts[1].outcome_email_present?[0]
        assert !muts[2].outcome_name_present?[0]
        assert muts[2].outcome_email_present?[0]
        assert muts[3].outcome_name_present?[0]
        assert muts[3].outcome_email_present?[0]
      end
    end

    describe "deal with ActiveRecord properly" do
      let(:master) { Master.create!(whatever: 'I am master') }
      let(:slaves) do
        1.upto(10).each do |i|
          Slave.create!(whatever: "I am slave ##{i} :(", master_id: master.id)
        end
      end

      class CommandReturningRelation < Mutations::CommandReturningArray
        required do
          model :master, class: Master
        end

        outcome_required do
          array :slaves, class: Slave
        end

        def execute
          master.slaves
        end
      end

      it "should handle ActiveRecord::Relation as an array outcome" do
        assert CommandReturningRelation.new(master: master).run.success?
      end
    end

  end
end
