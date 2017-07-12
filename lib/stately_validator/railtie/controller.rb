module StatelyValidator
  class Railtie
    module Controller
      require "active_support/concern"
      extend ActiveSupport::Concern
      
      def validate_with(name, options = {})
        # Find the validator
        validator_class = load_validator name
        return nil unless validator_class
        
        validator.set_action_controller self
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