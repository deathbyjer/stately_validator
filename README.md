# stately_validator

This is a Ruby gem that has been built to allow for validations with state.

#### Why not ActiveRecord Validations?

ActiveRecord validations are phenominal for validating data. An ActiveRecord, by design, should be separated from the state of the controller / user that is using it. Therefore, the actual validations shoudl be data-centric, on what is allowed by the database. However, what is allowed by the database may not be the same as what is allowed by the business logic. StatelyValidation is built to ride ontop of the ActionController and build out validation scripts that can be used which are aware of the current controller and request state.
