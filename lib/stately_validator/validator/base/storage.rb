module StatelyValidator
  class Validator
    class Base
      module Storage
        def self.included(base)
          base.extend(ClassMethods)
        end
        
        module ClassMethods
          # This function will indicate the fields to save, assuming they exist and passed all their tests
          #
          def store(fields, options = {})
            @store = {} unless @store.is_a?(Hash)
            
            options = prepare_skip_blocks options
            
            Utilities.to_array(fields).each {|field| @store[field] = options }
          end
          
          def stores
            @store || {}
          end
        end
        
        def stores
          self.class.stores
        end
              
        def store!(options = {})
          return false unless valid? || options[:on_error]
          @params.merge(values(true)).each do |k,v|
            #Skip any fields not in store if there are fields there
            next if stores.empty? || stores[k].nil?
            
            # FIrst, if the user put in their own field, only store those
            next unless !options[:fields].is_a?(Array) || options[:fields].include?(k)
            
            # Now, we are going to need to know if we are transforming this item for storage
            store_opts = stores[k] || {}
            
            # Now we are going to skip based on internal errors, external errors and state
            next if skip_validation?(store_opts)
            
            new_val = _transform_for_storage k, v, store_opts[:method], store_opts[:class]            
            
            return if self.errors[k]
            
            _store_set k, new_val, store_opts
          end
        end
        
        # Store the transformed / checked values into an object
        def store_into(object, options = {})
          return false unless valid? || options[:on_error]
          set_model object
          store! options
        end
        
        protected
        
        def _transform_for_storage(key, val, method, klass = nil)  
          # Return the value unless method is a symbol
          return val unless method.is_a?(Symbol)
          
          # Now, we are going to try different ways to transform the object, if they have
          # Been given by the validator
          if self.respond_to?(method)
            return case self.method(method).arity
            when 1
              self.send(method, val)
            when 2
              self.send(method, model, val)
            else
              self.send(method, model, val, key)
            end
          end
          
          return model.send(method, val) if model.respond_to?(method)
          
          if klass.is_a?(Module) && klass.respond_to?(method)
            return case klass.method(method).arity
            when 1
              klass.send(method, val)
            when 2
              klass.send(method, model, val)
            else
              klass.send(method, model, val, key)
            end
          end        
          
          # If all these have failed, then just return the value
          val
        end
        
        def _store_set(key, val, options)        
          # If the set method exists for the model, use that
          return model.send("#{key}=".to_sym, val) unless options[:set]
          
          Utilities.to_array(options[:set]).each do |set|
            if options[:iterate]
              Utilities.to_array(val).each {|v| _store_set_method(model, set, key, v) }
            else
              _store_set_method(model, set. key, val)
            end
          end
        end
        
        def _store_set_method(model, set, key, val)
          if model.respond_to?(set)
            case model.method(set).arity
            when 0
              model.send(set)
            when 1
              model.send(set, val)
            when 2
              model.send(set, key, val)
            end
          # Otherwise, if the set method exists here, use *that*
          elsif respond_to?(set)
            case method(set).arity
            when 1
              send(set, val)
            when 2
              send(set, model, val)
            when 3
              send(set, model, key, val)
            end
          end                
        end
        
      end
    end
  end
end