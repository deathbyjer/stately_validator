module StatelyValidator
  class Validator
    class Base
     
      def self.key(name_str = nil)
        unless name_str.nil? || @name == name_str
          @name = name_str.to_sym
          Validator.register_validator(self)
        end
        
        @name
      end
      
      # This is the main method for setting up our validations.
      # The order in which the methods are called are important.
      def self.validate(fields, validation, options = {})
        @validations = [] unless @validations.is_a?(Array)
        
        # We just need to log the validations, in order, for when we actually call the validation
        @validations << { fields: fields, validation: validation, options: options }
      end
      
      # Sometimes, we may want to execute an action during the flow of validations.
      # This would be used to generate an item needed to subsequent validations
      #
      # The fields argument, in this case, would be all the fields that need to be free-and-clear of errors#
      # in order to proceed with the execution
      def self.execute_on(fields, method, options = {})
        @validations = [] unless @validations.is_a?(Array)
        @validations << { execute: true, fields: fields, method: method, options: options }
      end
      
      # This function will transform a field into something else
      #
      # The translated value will replace it in "params"
      def self.transform(fields, method, options = {})
        @validations = [] unless @validations.is_a?(Array)
        @validations << { transform: true, fields: fields, method: method, options: options }
      end
      
      # This function will indicate the fields to save, assuming they exist and passed all their tests
      #
      def self.store(fields, options = {})
        @store = {} unless @store.is_a?(Hash)
        Utilities.to_array(fields).each {|field| @store[field] = options }
      end
      
      def self.validations
        @validations || []
      end
      
      def self.stores
        @store || {}
      end
      
      def stores
        self.class.stores
      end
      
      def self.notes
        @notes || []
      end
      
      def self.note(field)
        @notes = [] unless @notes.is_a?(Array)
        @notes << field
      end
      
      def params=(params)
        @ran = false
        if params.is_a?(Hash)
          @params = {}; params.each {|k,v| @params[k.to_s.to_sym] = v} 
        elsif params.respond_to?(:to_hash)
          @params = {}; params.to_hash.each {|k,v| @params[k.to_s.to_sym] = v}
        end
      end
      
      def set_param(name, value)
        name = name.to_s.to_sym
        @params = {} unless @params.is_a?(Hash)
        @params[name] = value
      end
      
      # This is how we can set some internal variables, which are useful for 
      # validating. 
      # A note: An internal will be overloaded 
      def set_state(name, value = true)
        @states = {} unless @states.is_a?(Hash)
        @states[name.to_sym] = value
      end
      
      def state
        return false unless @states.is_a?(Hash)
        @states[name.to_sym]
      end
      
      def state?(name)
        state(name) || false
      end
      
      def params
        @params || {}
      end
      
      def errors
        @errors || {}
      end
      
      def states
        @states || {}
      end
      
      def values(pure = false)
        (pure ? {} : params).merge(@values || {})
      end
      
      def set_value(name, value)
        name = name.to_s.to_sym
        @values = {} unless @values.is_a?(Hash)
        @values[name] = value
      end
      
      def param(name)
        return nil if name.nil?
        params[name.to_s.to_sym]
      end
      
      def value(name)
        return nil if name.nil?
        val = values[name.to_s.to_sym]
        return val unless val.nil? || val.to_s.empty?
        params[name.to_s.to_sym]
      end
      
      def validate(new_params = nil)
        if new_params.is_a?(Hash)
          @ran = false
          @params = {}; new_params.each{|k,v| @params[k.to_s.to_sym] = v}
        end
 
        @errors = {}
        @internal = {}
        @notes = {}; self.class.notes.each {|n| @notes[n] = param(n) if param(n)}
        
        self.class.validations.each do |details|
          # Are we skipping this because some of the items have failed their validations?
          opts = details[:options]
          next if (Utilities.to_array(details[:fields]) + (opts[:as] ? [opts[:as]] : [])).any?{|k| @errors[k]}
        
          # Gather the values to send in
          vals = Utilities.to_array(details[:fields]).map{|f| value(f)}
          vals = vals.first if vals.count == 1
          
          # Now we are going to skip based on internal errors, external errors and state
          next if skip_validation?(opts)
          
          # If we are executing, then just execute and go to the next step
          if details[:execute]
            execute vals, details[:method], opts
            next
          end
          
          # Transform the relevant fields
          if details[:transform]
            Utilities.to_array(details[:fields]).each {|f| transform f, details[:method], opts}
            next
          end
          
          # Attempt the validation
          err = Validation.validate(vals, details[:fields], details[:validation], self, opts)
          # Pass if the error is nil or is TrueClass
          next if err.nil? || err == true
          
          err = opts[:error] if opts[:error]
          
          # We should be able to set multiple error names to the same thing
          if opts[:as].is_a?(Array)
            opts[:as].each { |as| (opts[:internal] ? @internal : @errors)[as] = err }
          # But to do that, the :as variable needs to be explicit. Otherwise, default to the first parameter
          else
            (opts[:internal] ? @internal : @errors)[opts[:as] || Utilities.to_array(details[:fields]).first] = err
          end
        end
        
        @ran = true
      end
      
      def valid?
        return nil unless @ran
        @errors.empty?
      end
      
      # Store the transformed / checked values into an object
      def store_into(object, options = {})
        return false unless valid? || options[:on_error]

        @params.merge(values(true)).each do |k,v|
          #Skip any fields not in store if there are fields there
          next unless stores.empty? || stores[k]
          
          # FIrst, if the user put in their own field, only store those
          next unless !options[:fields].is_a?(Array) || options[:fields].include?(k)
          
          # Now, we are going to need to know if we are transforming this item for storage
          store_opts = stores[k] || {}
          
          # Now we are going to skip based on internal errors, external errors and state
          next if skip_validation?(store_opts)
          
          new_val = v
          
          # Now, we are going to try different ways to transform the object, if they have
          # Been given by the validator
          if store_opts[:method].is_a?(Symbol)
            if self.respond_to?(store_opts[:method])
              new_val = self.send(store_opts[:method], object, v, k)
            elsif object.respond_to?(store_opts[:method])
              new_val = object.send(store_opts[:method])
            elsif store_opts[:class].is_a?(Module) && store_opts[:class].respond_to?(store_opts[:method])
              new_val = store_opts[:class].send(store_opts[:method], object, v, k)
            end
          end
          
          (options[:set] ? object.send(options[:set], k, new_val) : object.send("#{k}=".to_sym, new_val)) unless self.errors[k]
        end
      end
      
      protected
      
      def self.validations
        @validations || []
      end
      
      private
      
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
        new_val = send(method, val) if new_val.nil? && respond_to?(method) 
        new_val = opts[:class].send(method, self, val) if new_val.nil? && opts[:class].is_a?(Module) && opts[:class].respond_to?(method)
        return unless new_val
        
        set_value field, new_val
      end
      
      def skip_validation?(opts)
        # We are going to evaluate the skip_if condition
        return evaluate_skip_array(opts[:skip_if], :and) if opts[:skip_if]
        return !evaluate_skip_array(opts[:skip_unless], :and) if opts[:skip_unless]
        false
      end
      
      # We are going to evaluate the skip array and see if all the values 
      def evaluate_skip_array(conditions, operator = :and)
        conditions = [ conditions ] unless conditions.is_a?(Array)
        operator == :and ? conditions.all?{|c| evaluate_skip_condition(c, operator)} : conditions.any?{|c| evaluate_skip_condition(c, operator)}
      end
      
      def evaluate_skip_condition(condition, operator = :and)
        # If the condition is a string, convert it to a symbol
        condition = condition.to_sym if condition.is_a?(String)
        
        # If the condition is just the existence of an error or an internal error, then just check for that
        return states[condition] || @notes[condition] || @internal[condition] || @errors[:condition] if condition.is_a?(Symbol)
        
        # If the condition is an array, then we need to evaluate it according to the opposite operator of this array
        return evaluate_skip_array(condition, operator == :and ? :or : :and) if condition.is_a?(Array)
        
        # The only thing left to evaluate is a hash. So if it's not a hash, return that this is fine 
        return true unless condition.is_a?(Hash)
        
        # If the condition is a hash, then it depends on the size of the hash.
        # IF the size of the has is 0, then it evaluates to true
        return true if condition.empty?
        
        # If the condition has more than one item, turn it into an array of one-item conditions
        return evaluate_skip_array(condition.keys.map{|k| {k => condition[k]}}, operator == :and ? :or : :and) if condition.count > 1
        
        # Now we need to evaluate the condition hash
        k,v = condition.first
        [@errors, @internal, states, @notes].each { |check| return true if check[k].eql?(v) }
        
        # Otherwise, just return false
        false
      end
    end
    
  end
end