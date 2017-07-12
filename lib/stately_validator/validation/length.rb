module StatelyValidator
  class Validation
    
    class Length < Base
      key :length
      
      def self.validate(value, names = [], options = {})
        return "too_short" if options[:min] && value.length < options[:min]
        return "too_long" if options[:max] && value.length > options[:max]
        true
      end
    end
  end
end