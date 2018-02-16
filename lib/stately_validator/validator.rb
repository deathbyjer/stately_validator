module StatelyValidator
  class Validator
    def self.validator_for(name)
      return name if name.is_a?(Base)
      @validators = {} unless @validators.is_a?(Hash)
      @validators[name.to_sym]
    end
    
    def self.register_validator(validator)
      @validators = {} unless @validators.is_a?(Hash)
      @validators[validator.key.to_sym] = validator
    end
    
    require "stately_validator/validator/base"
  end
end