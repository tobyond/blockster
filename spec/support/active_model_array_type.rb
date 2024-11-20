# frozen_string_literal: true

module Blockster
  class ArrayType < ActiveModel::Type::Value
    def initialize(subtype = :string)
      @subtype = subtype
    end

    def cast(value)
      case value
      when ::Array then value
      when String then begin
        JSON.parse(value)
      rescue StandardError
        [value]
      end
      when nil then []
      else [value]
      end
    end

    def serialize(value)
      case value
      when ::Array then value
      when nil then []
      else [value]
      end
    end

    def changed_in_place?(raw_old_value, new_value)
      cast(raw_old_value) != cast(new_value)
    end
  end
end

# Register the type
ActiveModel::Type.register(:array, Blockster::ArrayType)
# Also register with ActiveRecord if it's available
ActiveRecord::Type.register(:array, Blockster::ArrayType) if defined?(ActiveRecord)
