# frozen_string_literal: true

module Blockster
  class Wrapper
    extend Forwardable
    def_delegators :to_h, :each_pair, :each, :empty?, :keys

    def initialize(klass = nil)
      @klass = klass || Blockster.default_class
      raise ArgumentError, "No class provided and no default_class configured" unless @klass
      @root_key = nil
    end

    def with(attributes = {}, &block)
      raise ArgumentError, "Attributes must be a hash" unless attributes.is_a?(Hash)

      temp_class = Class.new(@klass)
      context = Context.new(temp_class, self)
      context.instance_eval(&block) if block_given?

      attributes = attributes[@root_key.to_s] if @root_key && attributes.key?(@root_key.to_s)

      @instance = temp_class.new
      set_nested_attributes(symbolize_keys(attributes))
      self
    end

    def to_h
      return {} unless @instance

      collected_attributes = {}

      # Get defined attributes
      if @instance.class.respond_to?(:attribute_types)
        @instance.class.attribute_types.keys.each do |attr_name|
          value = @instance.public_send(attr_name)
          collected_attributes[attr_name.to_sym] = convert_value_to_hash(value)
        end
      end

      # Get nested attributes
      if @instance.class.respond_to?(:nested_attributes)
        @instance.class.nested_attributes.each_key do |attr_name|
          nested_value = instance_variable_get("@#{attr_name}")
          collected_attributes[attr_name.to_sym] = nested_value&.to_h || {}
        end
      end

      collected_attributes
    end

    def inspect
      to_h.inspect
    end

    def to_hash
      to_h
    end

    def as_json(options = nil)
      to_h
    end

    def to_json(options = nil)
      as_json(options).to_json
    end

    private

    def convert_value_to_hash(value)
      case value
      when Wrapper
        value.to_h
      when Array
        value.map { |v| convert_value_to_hash(v) }
      else
        value
      end
    end

    def set_nested_attributes(attributes)
      return unless attributes.is_a?(Hash)

      @instance.class.nested_attributes&.each do |name, config|
        # Define accessor method for nested attribute on the wrapper
        define_singleton_method(name) do
          instance_variable_get("@#{name}")
        end

        if attributes.key?(name)
          klass = Class.new(@klass)

          nested_wrapper = self.class.new(klass)
          nested_wrapper.with(attributes[name], &config)

          instance_variable_set("@#{name}", nested_wrapper)
        else
          # Initialize empty wrapper even if no attributes provided
          klass = Class.new(@klass)
          nested_wrapper = self.class.new(klass)
          nested_wrapper.with({}, &config)
          instance_variable_set("@#{name}", nested_wrapper)
        end
      end

      # Set regular attributes
      attributes.each do |key, value|
        next if @instance.class.nested_attributes&.key?(key)
        setter = "#{key}="
        @instance.send(setter, value) if @instance.respond_to?(setter)
      end
    end

    def symbolize_keys(hash)
      return {} unless hash.is_a?(Hash)
      hash.transform_keys { |key| key.to_sym rescue key }
    end

    def method_missing(method_name, *args, &block)
      if @instance&.respond_to?(method_name)
        result = @instance.send(method_name, *args, &block)
        if result == @instance
          self
        else
          result
        end
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      @instance&.respond_to?(method_name, include_private) || super
    end
  end
end
