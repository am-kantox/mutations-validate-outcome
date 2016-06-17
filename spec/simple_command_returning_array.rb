class SimpleCommandReturningArray < Mutations::CommandReturningArray
  required do
    desc 'The name of length not more than 10 symbols'
    string :name, max_length: 10

    desc 'The email'
    string :email
  end

  optional do
    desc 'The amount'
    integer :amount
  end

  outcome_required do
    desc 'The name of length not more than 5 symbols'
    string :name, max_length: 5

    string :email
  end

  outcome_optional do
    desc 'The amount'
    integer :amount
  end

  def validate
    add_error(:email, :invalid, 'Email must contain @') unless email && email.include?('@')
  end

  def execute
    [inputs.dup, { name: 'John', email: 'aleksei@gmail.com'}.with_indifferent_access]
  end

  def validate_outcome(outcome)
    add_outcome_error(:name, :invalid, 'Name must contain john') unless outcome[:name] && outcome[:name].include?('John')
  end
end
