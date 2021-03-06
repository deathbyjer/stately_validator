module StatelyValidator
  class Validation
  
    class Matches < Base
      key :matches
      
      def self.validate(values, names = [], options = {})
        return "incorrect" if options[:in] && options[:in].is_a?(Array) && !(Utilities.to_array(values) - options[:in]).empty?
        return "incorrect" if options[:key] && options[:key].is_a?(Hash) && Utilities.to_array(values).any?{|k| not options[:key][k]}
        
        if options[:regex]
          Utilities.to_array(options[:regex]).each do |regex|
            return "incorrect" unless regex.is_a?(Regexp) && Utilities.to_array(values).all?{|v| v.to_s =~ regex}
          end
        end
        true
      end
    end
  end
end