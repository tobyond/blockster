# frozen_string_literal: true

require "spec_helper"

RSpec.describe Blockster::Wrapper do
  let(:model_class) do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Attributes
    end
  end

  context "with nested attributes" do
    it "handles nested attributes with root" do
      params = {
        "user" => {
          "username" => "js_bach",
          "email" => {
            "address" => "js@bach.music",
            "receive_updates" => false
          }
        }
      }

      result = described_class.new(model_class).with(params) do
        root :user do
          attribute :username, :string
          nested :email do
            attribute :address, :string
            attribute :receive_updates, :boolean
          end
        end
      end

      expect(result.username).to eq("js_bach")
      expect(result.email.address).to eq("js@bach.music")
      expect(result.email.receive_updates).to be false
    end

    it "handles array attributes with custom type" do
      params = {
        "user" => {
          "hobbies" => {
            "instruments" => %w[guitar piano],
            "sports" => %w[running skiing]
          }
        }
      }

      result = described_class.new(model_class).with(params) do
        root :user do
          nested :hobbies do
            attribute :instruments, :array
            attribute :sports, :array
          end
        end
      end

      expect(result.hobbies.instruments).to eq(%w[guitar piano])
      expect(result.hobbies.sports).to eq(%w[running skiing])
    end
  end

  describe "Hash-like behavior" do
    it "converts to hash" do
      result = described_class.new(model_class).with(username: "test") do
        attribute :username, :string
        nested :email do
          attribute :address, :string
        end
      end

      expect(result.to_h).to eq({
        username: "test",
        email: { address: nil }
      })
    end

    it "supports nested attribute conversion" do
      result = described_class.new(model_class).with(
        username: "test",
        email: { address: "test@example.com" }
      ) do
        attribute :username, :string
        nested :email do
          attribute :address, :string
        end
      end

      expect(result.to_h).to eq({
        username: "test",
        email: { address: "test@example.com" }
      })
    end

    it "supports hash delegation methods" do
      result = described_class.new(model_class).with(username: "test") do
        attribute :username, :string
      end

      expect(result.keys).to eq([:username])
      expect(result.empty?).to be false

      pairs = []
      result.each_pair { |k, v| pairs << [k, v] }
      expect(pairs).to eq([[:username, "test"]])
    end
  end

  describe "ActiveRecord compatibility" do
    it "provides inspection" do
      result = described_class.new(model_class).with(username: "test") do
        attribute :username, :string
      end

      expect(result.inspect).to eq({ username: "test" }.inspect)
    end

    it "works with complex nested structures" do
      params = {
        "user" => {
          "username" => "js_bach",
          "email" => {
            "address" => "js@bach.music",
            "notifications" => true
          }
        }
      }

      result = described_class.new(model_class).with(params) do
        root :user do
          attribute :username, :string
          nested :email do
            attribute :address, :string
            attribute :notifications, :boolean
          end
        end
      end

      expect(result.to_h).to eq({
        username: "js_bach",
        email: {
          address: "js@bach.music",
          notifications: true
        }
      })
    end
  end

  describe "integration with ActiveRecord", :db do
    before do
      ActiveRecord::Base.establish_connection(
        adapter: "sqlite3",
        database: ":memory:"
      )

      ActiveRecord::Schema.define do
        create_table :users do |t|
          t.string :username
          t.string :email
          t.timestamps
        end
      end

      class User < ActiveRecord::Base
      end
    end

    after do
      ActiveRecord::Base.remove_connection
    end

    it "works with ActiveRecord create" do
      result = described_class.new(model_class).with(
        username: "test",
        email: "test@example.com"
      ) do
        attribute :username, :string
        attribute :email, :string
      end

      user = User.create(result)
      expect(user).to be_persisted
      expect(user.username).to eq("test")
      expect(user.email).to eq("test@example.com")
    end
  end

  describe "JSON serialization" do
    let(:model_class) do
      Class.new do
        include ActiveModel::Model
        include ActiveModel::Attributes
      end
    end

    it "supports as_json" do
      result = described_class.new(model_class).with(
        'user' => {
          'name' => "Test",
          'email' => {
            'address' => "test@example.com"
          }
        }
      ) do
        root :user do
          attribute :name, :string
          nested :email do
            attribute :address, :string
          end
        end
      end

      expected = {
        name: "Test",
        email: { address: "test@example.com" }
      }

      expect(result.as_json).to eq(expected)
    end

    it "supports to_json" do
      result = described_class.new(model_class).with(
        'user' => {
          'name' => "Test",
          'email' => {
            'address' => "test@example.com"
          }
        }
      ) do
        root :user do
          attribute :name, :string
          nested :email do
            attribute :address, :string
          end
        end
      end

      expected = {
        name: "Test",
        email: { address: "test@example.com" }
      }.to_json

      expect(result.to_json).to eq(expected)
    end

    it "works with nested arrays" do
      result = described_class.new(model_class).with(
        'user' => {
          'name' => "Test",
          'hobbies' => {
            'sports' => ["running", "swimming"]
          }
        }
      ) do
        root :user do
          attribute :name, :string
          nested :hobbies do
            attribute :sports, :array
          end
        end
      end

      expect(JSON.parse(result.to_json)).to eq({
        "name" => "Test",
        "hobbies" => {
          "sports" => ["running", "swimming"]
        }
      })
    end
  end
end
