# frozen_string_literal: true

require "zeitwerk"
require "json"

loader = Zeitwerk::Loader.for_gem
loader.setup

module Blockster
  class Error < StandardError; end
end
