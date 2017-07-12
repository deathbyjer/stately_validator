module StatelyValidator
  VERSION = "0.0.1"
  
  require "stately_validator/validator"
  require "stately_validator/validation"
  require "stately_validator/utilities"
  
  require "stately_validator/railtie" if defined?(Rails)
  
end