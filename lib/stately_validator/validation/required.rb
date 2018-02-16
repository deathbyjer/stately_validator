module StatelyValidator
  class Validation
  
    class Required < Base
      key :required
      on_nil true
      
      def self.validate(values, names = [], options = {})
        return true if check_model(values, names, options[:validator], options)
        return "required" if Utilities.to_array(values).all?{|v| v.nil? || v.to_s.empty?}
        true
      end
      
      def self.check_model(vals, names, validator, options = {})
        return false unless validator && validator.model
        return false unless options[:can_be_empty_if_in_model] || Utilities.to_array(vals).all?{|v| v.nil?}
        Utilities.to_array(names).none? do |n| 
          if validator.model.respond_to?(n)
            v = validator.model.send(n)
            v.nil? || v.to_s.empty?
          else
            false
          end
        end
      end
    end
  end
end