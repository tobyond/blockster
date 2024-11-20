# frozen_string_literal: true

module Blockster
  class Configuration
    attr_accessor :default_class

    def initialize
      @default_class = nil
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def default_class
      configuration.default_class
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
