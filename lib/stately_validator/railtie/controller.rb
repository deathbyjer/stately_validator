module StatelyValidator
  class Railtie
    module Controller
      require "active_support/concern"
      extend ActiveSupport::Concern
      
      # We may want to globally set the state for any validators loaded. 
      # Things like "is_logged_in" or "is_admin"
      def set_validator_state(name, value = true)
        return unless name
        name = name.to_sym
        
        @validator_states = {} unless @validator_states.is_a?(Hash)
        @validator_states[name] = value
      end
      
      def preset_validator_value(name, value)
        return unless name
        name = name.to_sym
        
        @validator_values = {} unless @validator_values.is_a?(Hash)
        @validator_values[name] = value
      end
      
      def validate_with(name, options = {})
        # Find the validator
        validator = load_validator name
        return nil unless validator
        
        validator.set_action_controller self
        (@validator_states || {}).each {|n,v| validator.set_state n, v}
        
        p = {}; params.send(params.respond_to?(:to_unsafe_h) ? :to_unsafe_h : :to_h).each {|k,v| p[k.to_s.to_sym] = v}
        
        validator.params = p
        (@validator_values || {}).each {|n,v| validator.set_value n, v}
        begin
          validator.validate unless options[:dont_validate]
        rescue Exception => e
          Rails.logger.error e.message
          Rails.logger.error e.backtrace.join("\n")
          raise "Error Thrown by StatelyValidator"
        end
        validator
      end
      
      
      private
      
      def load_validator(name)
        validator = nil
        validator = name if name.is_a?(Module) && name.ancestors.include?(Validator::Base)
        validator = Validator.validator_for(name) if name.is_a?(Symbol)
        validator ? validator.new : nil
      end
    end
  end
end