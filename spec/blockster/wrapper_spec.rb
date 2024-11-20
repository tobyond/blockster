# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blockster::Wrapper do
  context "with nested attributes" do
    let(:model_class) do
      Class.new do
        include ActiveModel::Model
        include ActiveModel::Attributes
      end
    end

    it "handles nested attributes with root" do
      params = {
        'user' => {
          'username' => 'js_bach',
          'email' => {
            'address' => 'js@bach.music',
            'receive_updates' => false
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

      expect(result.username).to eq('js_bach')
      expect(result.email.address).to eq('js@bach.music')
      expect(result.email.receive_updates).to be false
    end

    it "handles array attributes with custom type" do
      params = {
        'user' => {
          'hobbies' => {
            'instruments' => ['guitar', 'piano'],
            'sports' => ['running', 'skiing']
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

      expect(result.hobbies.instruments).to eq(['guitar', 'piano'])
      expect(result.hobbies.sports).to eq(['running', 'skiing'])
    end
  end
end
