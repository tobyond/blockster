# frozen_string_literal: true

module Blockster
  class Wrapper
    def initialize(klass)
      @klass = klass
    end

    def with(attributes = {}, &block)
      raise ArgumentError, "Attributes must be a hash" unless attributes.is_a?(Hash)

      # Create a bare Class that delegates to the original
      temp_class = Class.new(@klass)

      # Apply the configuration block
      Context.new(temp_class).instance_eval(&block) if block_given?

      # Create and configure instance
      @instance = temp_class.new
      set_attributes(symbolize_keys(attributes))
      @instance
    end

    private

    def symbolize_keys(hash)
      hash.transform_keys { |key| key.to_sym rescue key }
    end

    def set_attributes(attributes)
      attributes.each do |key, value|
        setter = "#{key}="
        @instance.send(setter, value) if @instance.respond_to?(setter)
      end
    end

    def method_missing(method_name, *args, &block)
      if @instance&.respond_to?(method_name)
        @instance.send(method_name, *args, &block)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      @instance&.respond_to?(method_name, include_private) || super
    end
  end

  class Context
    def initialize(temp_class)
      @temp_class = temp_class
    end

    def method_missing(method_name, *args, &block)
      if @temp_class.respond_to?(method_name, true)
        @temp_class.send(method_name, *args, &block)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      @temp_class.respond_to?(method_name, include_private) || super
    end
  end
end
