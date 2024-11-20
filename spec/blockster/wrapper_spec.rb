# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blockster::Wrapper do
  context "with ActiveModel attributes" do
    let(:model_class) do
      Class.new do
        include ActiveModel::Model
        include ActiveModel::Attributes
      end
    end

    it "allows defining and setting attributes" do
      result = described_class.new(model_class).with(name: "Test", count: 42) do
        attribute :name, :string
        attribute :count, :integer
      end

      expect(result.name).to eq("Test")
      expect(result.count).to eq(42)
    end

    it "maintains ActiveModel functionality" do
      result = described_class.new(model_class).with(name: "Test") do
        attribute :name, :string
        validates :name, presence: true
      end

      expect(result.valid?).to be true
      result.name = nil
      expect(result.valid?).to be false
    end
  end

  context "with custom DSL" do
    let(:custom_class) do
      Class.new do
        class << self
          def property(name, type = String)
            attr_accessor name
          end
        end
      end
    end

    it "works with custom property definitions" do
      result = described_class.new(custom_class).with(name: "Test") do
        property :name
        property :age, Integer
      end

      expect(result.name).to eq("Test")
      expect(result.respond_to?(:age)).to be true
    end
  end

  context "with inheritance" do
    let(:parent_class) do
      Class.new do
        def self.inherited(child)
          child.include ActiveModel::Model
          child.include ActiveModel::Attributes
        end

        def parent_method
          "from parent"
        end
      end
    end

    it "maintains inheritance chain functionality" do
      result = described_class.new(parent_class).with(name: "Test") do
        attribute :name, :string
      end

      expect(result.parent_method).to eq("from parent")
      expect(result.name).to eq("Test")
    end
  end

  context "with complex modules" do
    module TestModule
      def module_method
        "from module"
      end
    end

    let(:complex_class) do
      klass = Class.new do
        include TestModule
        include ActiveModel::Model
        include ActiveModel::Attributes
      end
      klass.attribute :predefined, :string
      klass
    end

    it "maintains all module functionality" do
      result = described_class.new(complex_class).with(
        predefined: "old",
        name: "new"
      ) do
        attribute :name, :string
      end

      expect(result.module_method).to eq("from module")
      expect(result.predefined).to eq("old")
      expect(result.name).to eq("new")
    end
  end

  context "error handling" do
    let(:base_class) { Class.new }

    it "raises error for non-hash attributes" do
      expect {
        described_class.new(base_class).with(nil) { }
      }.to raise_error(ArgumentError, "Attributes must be a hash")
    end

    it "handles missing methods gracefully" do
      expect {
        described_class.new(base_class).with do
          nonexistent_method :name
        end
      }.to raise_error(NoMethodError)
    end
  end
end
