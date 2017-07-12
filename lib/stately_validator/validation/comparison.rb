module StatelyValidator
  class Validation
    
    class Comparison < Base
      key :compare
    
      def self.validate(values, name = [], options = {})
        return "too_large" if options[:lt] && options[:lt].respond_to?(:>) && !Utilities.to_array(values).all?{|v| options[:lt] > v}
        return "too_large" if options[:lte] && options[:lte].respond_to?(:>=) && !Utilities.to_array(values).all?{|v| options[:lte] >= v}
        
        return "too_small" if options[:gt] && options[:gt].respond_to?(:<) && !Utilities.to_array(values).all?{|v| options[:gt] < v}
        return "too_small" if options[:gte] && options[:gte].respond_to?(:<=) && !Utilities.to_array(values).all?{|v| options[:gte] <= v}
        return
      end
    end
  end
end