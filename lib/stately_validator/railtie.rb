module StatelyValidator
  class Railtie < Rails::Railtie
    require "stately_validator/railtie/controller"
    
    # We need to extend the Base before we load the validators
    require "stately_validator/validator/rails"
    
    initializer 'stately_validator.load_validator_from_controller' do
      ActiveSupport.on_load :action_controller do
        include Controller
      end
      
      # Setup a dependency requirement on all the validations
      Dir[(Rails.root + "app/validators/**/*_validator.rb")].each do |f| 
        require_dependency f   
      end
    end
    
    config.to_prepare do
      # Load everything in /validators, so that the keys can be properly loaded
      Dir[(Rails.root + "app/validators/**/*_validator.rb")].each do |f| 
        load f   
      end
    end
    
  end
end