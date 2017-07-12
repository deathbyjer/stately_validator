module StatelyValidator
  module Utilities
    def self.to_array(values)
      return values.values if values.is_a?(Hash)
      (values.is_a?(Array) ? values : [ values ])
    end
  end
end