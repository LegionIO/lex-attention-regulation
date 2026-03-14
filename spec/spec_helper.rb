# frozen_string_literal: true

require 'legion/extensions/attention_regulation/version'
require 'legion/extensions/attention_regulation/helpers/constants'
require 'legion/extensions/attention_regulation/helpers/attention_target'
require 'legion/extensions/attention_regulation/helpers/attention_controller'
require 'legion/extensions/attention_regulation/runners/attention_regulation'
require 'legion/extensions/attention_regulation/client'

module Legion
  module Extensions
    module Helpers
      module Lex; end
    end
  end
end

module Legion
  module Logging
    def self.method_missing(*); end
    def self.respond_to_missing?(*) = true
  end
end
