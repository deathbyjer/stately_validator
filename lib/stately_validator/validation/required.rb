module StatelyValidator
  class Validation
  
    class Required < Base
      key :required
      on_nil true
      
      def self.validate(values, names = [], options = {})
        return "required" if Utilities.to_array(values).all?{|v| v.nil? || v.to_s.empty?}
        true
      end
    end
  end
end