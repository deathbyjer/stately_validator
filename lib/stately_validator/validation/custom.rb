module StatelyValidator
  class Validation
    
    class Custom < Base
      key :custom
      
      def self.validate(values, name = [], options = {})
        # What is the expected output of this function? If it doesn't match, then throw the error
        expects = options.key?(:expects) ? options[:expects] : true
        
        # If sending in a class and method
        return "error" if options[:class].is_a?(Module) && options[:method].is_a?(Symbol) && options[:class].respond_to?(options[:method]) && expects != options[:class].send(options[:method], *Utilities.to_array(values))
        
        # If sending a method that can be run on the attached validator
        return "error" if options[:validator].is_a?(Validator::Base) && options[:method].is_a?(Symbol) && options[:validator].respond_to?(options[:method]) && expects != options[:validator].send(options[:method], *Utilities.to_array(values))
        
        # And finally, if sending a Proc
        return "error" if options[:proc].is_a?(Proc) && expects != options[:proc].call(*Utilities.to_array(values))
        
        true
      end
    end
  end
end