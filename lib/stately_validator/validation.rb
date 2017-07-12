module StatelyValidator
  class Validation    
    def self.validation_for(name)
      @validations = {} unless @validations.is_a?(Hash)
      @validations[name.to_sym]
    end
    
    def self.register_validation(validation)
      @validations = {} unless @validations.is_a?(Hash)
      @validations[validation.key.to_sym] = [] unless @validations[validation.key.to_sym].is_a?(Array)
      @validations[validation.key.to_sym] << validation
    end
    
    def self.validate(values, names = [], validation = nil, validator = nil, options = {})
      return unless options.is_a?(Hash) && validation
      validation = validation_for(validation) if validation.is_a?(Symbol)
      
      # Skip if the value is empty and we don't process on nil
      return unless validation.on_nil || Utilities.to_array(values).any?{|v| not v.nil? || v.to_s.empty?}
      
      # Now we are going to skip if we have states, and we don't match them
      # TODO
      
      # Now process the validation
      options[:validator] = validator
      result = validation.validate values, names, options
      result
    end
    
    class Base
     
      def self.key(name_str = nil)
        unless name_str.nil? || @name == name_str
          @name = name_str.to_sym
          Validation.register_validation(self)
        end
        
        @name
      end
      
      # This informs the validation if, by default, we are going to process
      # the validation anyway. By default, it's false but in some case (like :required)
      # We are going to need to set it to on.
      #
      # Note that this can be overriden inside the options with option[:on_nil]
      def self.on_nil(boolean = nil)
        return @process_on_nil if boolean.nil?
        
        @process_on_nil = boolean
      end
    
      # This is the generate validate call
      def self.validate(values, names = [], options = {})
        return false
      end
    end
  end
end

require "stately_validator/validation/defaults"