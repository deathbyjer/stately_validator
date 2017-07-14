# stately_validator

This is a Ruby gem that has been built to allow for validations with state.

#### Why not ActiveRecord Validations?

ActiveRecord validations are phenominal for validating data. An ActiveRecord, by design, should be separated from the state of the controller / user that is using it. Therefore, the actual validations shoudl be data-centric, on what is allowed by the database. However, what is allowed by the database may not be the same as what is allowed by the business logic. StatelyValidation is built to ride ontop of the ActionController and build out validation scripts that can be used which are aware of the current controller and request state.

## Basic Concepts

#### Validator
A collection of actions to be performed on input. These actions can be validations, transformations, storing as well as others

#### Validation
A validation is a static class that implements a _validate_ method that return nil if no validation is performed, true if the validation passes and a string error if the validation fails

## Validators

A validator is the main functional object of StatelyValidator. IT's where the declarative form of validations and changes to the input needs to be stored and it's the object that will perform said actions.

### Creating a Validator

All validators have two things in common:

1. They extend the StatelyValidator::Validator::Base class
2. They have a _key_ method that uniquely identifies them.

An example validator would look like this:
```
class ExampleValidator < StatelyValidator::Validator::Base
  key :example
end
```
