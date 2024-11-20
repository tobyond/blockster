# frozen_string_literal: true

module Blockster
  class Context
    def initialize(temp_class, wrapper)
      @temp_class = temp_class
      @wrapper = wrapper
      @temp_class.class_eval do
        class << self
          attr_accessor :nested_attributes
        end
        @nested_attributes = {}
      end
    end

    def root(key, &block)
      @wrapper.instance_variable_set("@root_key", key)
      instance_eval(&block)
    end

    def attribute(name, type, **_options)
      @temp_class.attribute(name, type)
    end

    def nested(name, &block)
      @temp_class.nested_attributes[name] = block
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
