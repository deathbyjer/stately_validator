module StatelyValidator
  class Validation
  
    class TypeCheck < Base
      key :check_types
      
      def self.validate(values, name = [], options = [])
        name = name.first if name.is_a?(Array)
        return unless name.is_a?(Symbol)
      
        values = [values] unless values.is_a?(Array)
        values.each do |value|
          case options[:is_a]
          when :string
            return "invalid" if value.nil?
          when :integer
            return "invalid" unless value.to_s =~ /^-?[0-9]+$/
          when :number
            return "invalid" unless value.to_s =~ /^-?[0-9]+(\.[0-9]*)?$/
          end
        end
        
        true
      end
    end
  
    class Ensure < Base
      key :ensure
      
      def self.validate(values, name = [], options = {})
        # Get the proper name
        name = name.first if name.is_a?(Array)
        
        return unless name.is_a?(Symbol)
        
        # We'll be golden, unless we need a cast
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
          when :symbol
            cast(values) { |v| v.to_sym }
          when :date
            cast(values) { |v| v.is_a?(String) ? Date.parse(v) : v.to_date}
          when :datetime
            cast(values) { |v| v.is_a?(String) ? DateTime.parse(v) : v.to_datetime}
          when :time
            cast(values) { |v| v.is_a?(String) ? Time.parse(v) : v.to_time}
          else
            raise unless check_types(values, options[:type])
            values
          end
        rescue
          return "invalid"
        end
        
        options[:validator].set_param(name, new_val) if options[:cast] && options[:validator].is_a?(Validator::Base)
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
      
      def self.check_types(values, type)
        return true unless type.is_a?(Module)
        values = values.values if values.is_a?(Hash)
        
        return values.all?{|v| v.is_a?(type)} if values.is_a?(Array)
        values.is_a?(type)
      end
    end
  end
end