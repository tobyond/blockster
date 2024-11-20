require 'spec_helper'

RSpec.describe Blockster::Configuration do
  after(:each) do
    Blockster.reset_configuration!
  end

  it "raises error when no class provided and no default configured" do
    expect {
      Blockster::Wrapper.new
    }.to raise_error(ArgumentError, "No class provided and no default_class configured")
  end

  it "allows setting default_class with inline class definition" do
    Blockster.configure do |config|
      config.default_class = Class.new do
        include ActiveModel::Model
        include ActiveModel::Attributes
        
        attribute :custom_field, :string
      end
    end

    wrapper = Blockster::Wrapper.new
    result = wrapper.with(custom_field: "test") do
      attribute :custom_field, :string
    end

    expect(result.custom_field).to eq("test")
  end

  it "allows setting default_class with existing class" do
    custom_class = Class.new do
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :predefined, :string
    end

    Blockster.configure do |config|
      config.default_class = custom_class
    end

    wrapper = Blockster::Wrapper.new
    result = wrapper.with(predefined: "test")
    expect(result.predefined).to eq("test")
  end

  it "uses default_class for nested attributes" do
    custom_class = Class.new do
      include ActiveModel::Model
      include ActiveModel::Attributes
      
      attribute :default_field, :string, default: "default"
    end

    Blockster.configure do |config|
      config.default_class = custom_class
    end

    wrapper = Blockster::Wrapper.new
    result = wrapper.with(nested: {}) do
      nested :nested do
        attribute :custom_field, :string
      end
    end

    expect(result.nested.default_field).to eq("default")
  end

  it "allows initializing wrapper with provided class even without default_class" do
    custom_class = Class.new do
      include ActiveModel::Model
      include ActiveModel::Attributes
    end

    wrapper = Blockster::Wrapper.new(custom_class)
    result = wrapper.with(test: "value") do
      attribute :test, :string
    end

    expect(result.test).to eq("value")
  end

  it "prefers provided class over default_class" do
    provided_class = Class.new do
      include ActiveModel::Model
      include ActiveModel::Attributes
      
      attribute :custom_default, :string, default: "custom"
    end

    default_class = Class.new do
      include ActiveModel::Model
      include ActiveModel::Attributes
      
      attribute :default_field, :string, default: "default"
    end

    Blockster.configure do |config|
      config.default_class = default_class
    end

    wrapper = Blockster::Wrapper.new(provided_class)
    result = wrapper.with({})
    expect(result.custom_default).to eq("custom")
    expect(result.respond_to?(:default_field)).to be false
  end
end
