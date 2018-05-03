module StatelyValidator
  class Validator
    class Base
      module Children
        def self.included(base)
          base.extend(ClassMethods)
        end
        
        module ClassMethods
          # We can assign a specific validator to operate on a certain parameter (item or array)
          def validate_child(field, validator, options = {})
            # Also, take note of this validator
            # We are going to use it to store, if we want to store
            @child_validators = {} unless @validator_for.is_a?(Hash)
            @child_validators[field] = validator
            
            options = prepare_skip_blocks options
            add_to_validation_steps(child_validator: true, child: field, options: options, validators: nil)
          end
          
          def store_child(field, options = {})
            @child_storage = {} unless @child_storage.is_a?(Hash)
            @child_storage[field] = options
          end
          
          def child_validators
            @child_validators || {}
          end
          
          def child_storage
            @child_storage || {}
          end
        end
        
        protected
        
        def validate_child?(details)
          return false unless details[:child_validator]
          validate_child details[:child], details[:options]
          true
        end
        
        def validate_child(field, opts)
          validator = Validator.validator_for self.child_validators[field]
          return unless validator.is_a?(Base)
          
          err = opts[:multiple] ? _validate_children(validator, value(field)) : _validate_child(validator, value(field))
          set_error(field, err) if err
        end
        
        def store_child(field, into, opts)
          storage_options = self.class.child_storage[field]
          return unless storage_options
          return unless opts[:class].is_a?(Module) && opts[:adder].is_a?(Symbol)
          opts[:find] ||= :find
          opts[:id] ||= :id
          
        end
        
        def _store_child(data, id, into, opts)
          item = opts[:class].send(opts[:find], id || data[opts[:id]])
          item = opts[:class].new unless item
          
          # STORE INTO VALIDATOR
          
          into.send(opts[:adder], item)
        end
        
        def _validate_children(validator, value)
          err = {}
          if value.is_a?(Hash)
            value.each do |k,v|
              err[k] = _validate_child validator, v
              err.delete(k) unless err[k]
            end
          elsif value.is_a?(Array)
            value.each_index do |i|
              err[i] = _validate_child validator, value[i]
              err.delete(i) unless err[i]
            end
          end
          
          err.empty? ? false : err
        end
        
        def _validate_child(validator, val)
          return "incorrect" unless val.is_a?(Hash)
          validator = stately_generate validator
          validator.set_state model if model
          validator.params = val
          validator.validate
          validator.valid? ? false : validator.errors
        end
        
      end
    end
  end
end