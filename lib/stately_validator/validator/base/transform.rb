module StatelyValidator
  class Validator
    class Base
      module Transform
        def self.included(base)
          base.extend(ClassMethods)
        end
        
        module ClassMethods  
          # Sometimes, we may want to execute an action during the flow of validations.
          # This would be used to generate an item needed to subsequent validations
          #
          # The fields argument, in this case, would be all the fields that need to be free-and-clear of errors#
          # in order to proceed with the execution
          def execute_on(fields, method, options = {})
            @validations = [] unless @validations.is_a?(Array)
            
            options = prepare_skip_blocks options
            
            item = { execute: true, fields: fields, method: method, options: options }
            @validations << item unless @validations.include?(item) # #no Duplicates
          end
          
          # This function will transform a field into something else
          #
          # The translated value will replace it in "params"
          def transform(fields, method, options = {})
            @validations = [] unless @validations.is_a?(Array)
            
            options = prepare_skip_blocks options
           
            item = { transform: true, fields: fields, method: method, options: options }
            @validations << item unless @validations.include?(item)
          end
        end
        
        protected
      
        def execute_or_transform?(vals, details, opts)   
          return false unless [:execute, :transform].any?{|k| details[k]}
          return true unless Utilities.to_array(details[:fields]).all?{|k| value(k)} # All the required fields are not here
                    
          # If we are executing, then just execute and go to the next step
          if details[:execute]
            execute vals, details[:method], opts
            return true
          end
          
          # Transform the relevant fields
          if details[:transform]
            Utilities.to_array(details[:fields]).each {|f| transform f, details[:method], opts}
            return true
          end
          
          false
        end
        
        def execute(values, method, opts)
          return unless method
          method = method.to_sym
          
          return send(method, *values) if respond_to?(method) 
          return opts[:class].send(method, self, *values) if opts[:class].is_a?(Module) && opts[:class].respond_to?(method)
        end
        
        def transform(field, method, opts)
          return unless method
          method = method.to_sym
          
          val = value(field)
          return if val.nil? || val.to_s.empty?
          
          new_val = nil
          if new_val.nil? && opts[:class].is_a?(Module) && opts[:class].respond_to?(method)
            new_val = case opts[:class].method(method).arity
            when 0
              opts[:class].send(method)
            when 1
              opts[:class].send(method, val)
            # If only one item is required, then it's likely this function is NOT using the validator as
            # an argument. So we'll assume that it really just wants the val
            when -1
              opts[:class].send(method, val)
            else
              opts[:class].send(method, self, val) 
            end
          end
          
          new_val = send(method, val) if new_val.nil? && respond_to?(method) 
          new_val = val.send(method) if new_val.nil? && val.respond_to?(method)
          return unless new_val
          
          set_value field, new_val
        end
      
      end
    end
  end
end