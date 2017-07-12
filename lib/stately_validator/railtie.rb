module StatelyValidator
  class Railtie < Rails::Railtie
    require "stately_validator/railtie/controller"
    
    initializer 'stately_validator.load_validator_from_controller' do
      ActiveSupport.on_load :action_controller do
        include Controller
      end
    end
    
    require "stately_validator/validator/rails"
  end
end