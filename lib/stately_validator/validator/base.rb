module StatelyValidator
  class Validator
    class Base
    
     
      def self.key(name_str = nil)
        unless name_str.nil? || @name == name_str
          @name = name_str.to_sym
          Validator.register_validator(self)
        end
        
        @name
      end
      
      # This is the main method for setting up our validations.
      # The order in which the methods are called are important.
      def self.validate(fields, validation, options = {})
        @validations = [] unless @validations.is_a?(Array)
        
        # We just need to log the validations, in order, for when we actually call the validation
        @validations << { fields: fields, validation: validation, options: options }
      end
      
      def params=(params)
        @ran = false
        if params.is_a?(Hash)
          @params = params 
        elsif params.respond_to?(:to_hash)
          @params = params.to_hash
        end
      end
      
      def set_param(name, value)
        return unless name.is_a?(Symbol)
        @params = {} unless @params.is_a?(Hash)
        @params[name] = value
      end
      
      def params
        @params || {}
      end
      
      def errors
        @errors || {}
      end
      
      def validate(params = nil)
        if params.is_a?(Hash)
          @ran = false
          @params = params 
        end
        return false unless @params.is_a?(Hash)
 
        @errors = {}
      
        self.class.validations.each do |details|
          # Are we skipping this because some of the items have failed their validations?
          opts = details[:options]
          next if (Utilities.to_array(details[:fields]) + (opts[:as] ? [opts[:as]] : [])).any?{|k| @errors[k]}
        
          # Gather the values to send in
          vals = Utilities.to_array(details[:fields]).map{|f| @params[f]}
          vals = vals.first if vals.count == 1
          
          # Attempt the validation
          err = Validation.validate(vals, details[:fields], details[:validation], self, opts)
          # Pass if the error is nil or is TrueClass
          next if err.nil? || err == true
          
          err = opts[:error] if opts[:error]
          @errors[opts[:as] || Utilities.to_array(details[:fields]).first] = err
        end
        
        @ran = true
      end
      
      def valid?
        return nil unless @ran
        @errors.empty?
      end
      
      protected
      
      def set_value(name, value)
        @values = {} unless @values.is_a?(Hash)
        @values[name] = value
      end
      
      def self.validations
        @validations || []
      end
    end
    
  end
end