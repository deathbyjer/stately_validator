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
      
      def validate_with(name, options = {})
        # Find the validator
        validator = load_validator name
        return nil unless validator
        
        validator.set_action_controller self
        (@validator_states || {}).each {|n,v| validator.set_state n, v}
        
        validator.validate(params) unless options[:dont_validate]
        validator
      end
      
      
      private
      
      def load_validator(name)
        validator = nil
        validator = name if name.is_a?(StatelyValidator)
        validator = Validator.validator_for(name) if name.is_a?(Symbol)
        validator ? validator.new : nil
      end
    end
  end
end