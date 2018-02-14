module StatelyValidator
  class Validation
    
    # This just will add an expectation concept into a Validation
    module Expectations
      def compare_with_expectation(expects, value)
        if expects.is_a?(Hash)
          return value.is_a?(expects[:is_a]) if expects.key?(:is_a)
        end
        
        return value.to_s =~ expects if expects.is_a?(Regexp)
        value.eql?(expects)
      end
    end
    
    # The CUSTOM type of Validator allows us to do custom methods, defined on the validator or elsewhere
    class Custom < Base
      key :custom
      
      extend Expectations
      
      def self.validate(values, name = [], options = {})
        # What is the expected output of this function? If it doesn't match, then throw the error
        expects = options.key?(:expects) ? options[:expects] : true
        
        begin
          # If sending in a class and method
          if options[:class].is_a?(Module) && options[:method].is_a?(Symbol) && options[:class].respond_to?(options[:method])
            Utilities.to_array(values).each do |value|
              return "error" unless compare_with_expectation(expects, options[:class].send(options[:method], value))
            end
          end
          
          # If sending a method that can be run on the attached validator
          return "error" if options[:validator].is_a?(Validator::Base) && options[:method].is_a?(Symbol) && options[:validator].respond_to?(options[:method]) && !compare_with_expectation(expects, options[:validator].send(options[:method], *Utilities.to_array(values)))
          
          # And finally, if sending a Proc
          return "error" if options[:proc].is_a?(Proc) && !compare_with_expectation(expects, options[:proc].call(*Utilities.to_array(values)))
        rescue
          return "error" unless expects == :error
        end
        
        true
      end
    end
    
    # The METHOD typeo f validator allows us to call methods on returned elements. These methods can then be evaluated for their result
    class Method < Base
      key :method
      
      extend Expectations
      
      def self.validate(values, name = [], options = {})
        return nil unless options[:method].is_a?(Symbol)
        
        method = options[:method]
        expects = options.key?(:expects) ? options[:expects] : true
        return "error" unless compare_with_expectation(expects, Utilities.to_array(values).all? do |item| 
          item.respond_to?(method) && (item.method(method).arity > 0 ? item.send(method, *Utilities.to_array(options[:args])) : item.send(method))
        end)
        true
      end
    end
  end
end