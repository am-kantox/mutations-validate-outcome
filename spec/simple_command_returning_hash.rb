class SimpleCommandReturningHash < Mutations::CommandReturningHash
  required do
    string :name, max_length: 10
    string :email
  end

  optional do
    integer :amount
  end

  outcome_required do
    string :name, max_length: 5
    string :email
  end

  outcome_optional do
    integer :amount
  end

  def validate
    add_error(:email, :invalid, 'Email must contain @') unless email && email.include?('@')
  end

  def execute
    inputs
  end

  def validate_outcome(outcome)
    add_error(:name, :invalid, 'Name must contain john') unless outcome[:name] && outcome[:name].include?('John')
  end
end
