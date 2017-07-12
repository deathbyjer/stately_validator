module StatelyValidator
  class Validation
  
    class Matches < Base
      key :matches
      
      def self.validate(values, names = [], options = {})
        return "incorrect" if options[:in] && options[:in].is_a?(Array) && !(Utilities.to_array(values) - options[:in]).empty?
        return "incorrect" if options[:regex] && options[:regex].is_a?(Regexp) && !Utilities.to_array(values).all?{|v| v.to_s =~ options[:regex]}
        true
      end
    end
  end
end