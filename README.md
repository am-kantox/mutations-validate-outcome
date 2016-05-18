# Mutations::Validate::Outcome

[![Build Status](https://travis-ci.org/am-kantox/mutations-validate-outcome.png)](https://travis-ci.org/am-kantox/mutations-validate-outcome)
[![Code Climate](https://codeclimate.com/github/am-kantox/mutations-validate-outcome.png)](https://codeclimate.com/github/am-kantox/mutations-validate-outcome)
[![Test Coverage](https://codeclimate.com/github/am-kantox/mutations-validate-outcome/badges/coverage.svg)](https://codeclimate.com/github/am-kantox/mutations-validate-outcome/coverage)
[![Issue Count](https://codeclimate.com/github/am-kantox/mutations-validate-outcome/badges/issue_count.svg)](https://codeclimate.com/github/am-kantox/mutations-validate-outcome)

Mixin for [`cypriss/mutations`](https://github.com/cypriss/mutations) allowing validation of outcome
using the same techniques as an input validation by original gem.

## Installation

In your `Gemfile` make a following change:

```diff
- gem 'mutations'
+ gem 'mutations-validate-outcome'
```

In your code:

```diff
- require 'mutations'
+ require 'mutations-validate-outcome'
```

## Differences against [`cypriss/mutations`](https://github.com/cypriss/mutations)

* dropped a support for `1.9` and `j**`
* `CommandReturningHash` is a command, that is supposed to return… well, you guessed
* `outcome_required` and `outcome_optional` filters are introduced for the new `CommandReturningHash`
* `CommandReturningHash#validate_outcome` method is a sibling of `validate` for additional outcome validation

#### Example

```ruby
class SimpleCommandReturningHash < Mutations::CommandReturningHash
  required do
    string :name, max_length: 10
    string :email
  end

  optional do
    integer :amount
  end

  outcome_required do
    # outcome[:name] is to be shorter than 6 symbols
    string :name, max_length: 5
    # outcome[:email] is to be presented
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

  # outcome[:name] must include 'John' substring
  def validate_outcome(outcome)
    add_error(:name, :invalid, 'Name must contain john') unless outcome[:name].include?('John')
  end
end
```

#### TBD:

* `CommandReturningArrayOfHashes`

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
