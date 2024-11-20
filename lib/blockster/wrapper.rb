# frozen_string_literal: true

module Blockster
  class Wrapper
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
      @instance
    end

    private

    def set_nested_attributes(attributes)
      return unless attributes.is_a?(Hash)

      @instance.class.nested_attributes.each do |name, config|
        next unless attributes.key?(name)

        # Use the default class for nested attributes
        klass = Class.new(@klass)

        nested_wrapper = Wrapper.new(klass)
        nested_instance = nested_wrapper.with({}, &config)

        if attributes[name].is_a?(Hash)
          attributes[name].each do |key, value|
            setter = "#{key}="
            nested_instance.send(setter, value) if nested_instance.respond_to?(setter)
          end
        end

        @instance.instance_variable_set("@#{name}", nested_instance)
        @instance.define_singleton_method(name) { instance_variable_get("@#{name}") }
      end

      attributes.each do |key, value|
        next if @instance.class.nested_attributes.key?(key)

        setter = "#{key}="
        @instance.send(setter, value) if @instance.respond_to?(setter)
      end
    end

    def symbolize_keys(hash)
      return {} unless hash.is_a?(Hash)

      hash.transform_keys do |key|
        key.to_sym
      rescue StandardError
        key
      end
    end

    def method_missing(method_name, *args, &block)
      if @instance.respond_to?(method_name)
        @instance.send(method_name, *args, &block)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      @instance.respond_to?(method_name, include_private) || super
    end
  end

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
