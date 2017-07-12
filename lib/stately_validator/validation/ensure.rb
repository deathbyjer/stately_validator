module StatelyValidator
  class Validation
  
    class Ensure < Base
      key :ensure
      
      def self.validate(values, names = [], options = {})
        # Get the proper name
        name = name.first if names.is_a?(Array)
        return unless name.is_a?(Symbol)
        
        # We'll be golden, unless we need a cast
        return unless options[:cast]
        new_val = values
        begin
          new_val = case options[:cast]
          when :integer
            cast(values) { |v| v.to_i }
          when :float
            cast(values) { |v| v.to_f }
          when :decimal
            cast(values) { |v| v.to_f }
          when :string
            cast(values) { |v| v.to_s }
          else
            values
          end
        rescue
          return "invalid"
        end
        
        options[:validator].set_param(name, new_val) if options[:validator].is_a?(Validator::Base)
        true
      end
      
      private
      
      def self.cast(values, &block)
        out = values
        if values.is_a?(Hash)
          out = {}; values.keys.each{|k| out[k] = block.call(values[k])}
        elsif values.is_a?(Array)
          out = values.map{|v| block.call(v)}
        else
          out = block.call(values)
        end
      end
    end
  end
end