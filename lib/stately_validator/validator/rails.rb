module StatelyValidator
  class Validator
    module Rails
      
      def set_action_controller(ac)
        @action_controller = ac if ac.is_a?(ActionController::Base)
      end
      
      protected
      
      def controller
        @action_controller
      end
      
    end
    
    
    # And include this object to the Base
    require "stately_validator/validator/base"
    
    class Base
      include Rails 
    end
  end
end