# frozen_string_literal: true

module Legion
  module Extensions
    module AttentionRegulation
      module Helpers
        module Constants
          MAX_TARGETS     = 30
          MAX_HISTORY     = 200

          DEFAULT_RESOURCE  = 1.0
          RESOURCE_FLOOR    = 0.05
          RESOURCE_CEILING  = 1.0
          RESOURCE_DRAIN    = 0.02
          RESOURCE_RECOVERY = 0.03

          CAPTURE_THRESHOLD = 0.7

          DEFAULT_ZOOM  = 0.5
          ZOOM_FLOOR    = 0.1
          ZOOM_CEILING  = 1.0

          ATTENTION_MODES = %i[focused diffuse scanning resting captured].freeze
          TARGET_STATES   = %i[attended peripheral ignored].freeze

          RESOURCE_LABELS = {
            (0.8..)     => :abundant,
            (0.6...0.8) => :adequate,
            (0.4...0.6) => :moderate,
            (0.2...0.4) => :low,
            (..0.2)     => :depleted
          }.freeze
        end
      end
    end
  end
end
