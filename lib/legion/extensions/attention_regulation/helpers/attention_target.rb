# frozen_string_literal: true

module Legion
  module Extensions
    module AttentionRegulation
      module Helpers
        class AttentionTarget
          include Constants

          attr_reader :id, :name, :domain, :salience, :state, :attended_since

          def initialize(id:, name:, domain: :general, salience: 0.5)
            @id            = id
            @name          = name
            @domain        = domain
            @salience      = salience.to_f.clamp(0.0, 1.0)
            @state         = :peripheral
            @attended_since = nil
          end

          def attend!
            @state = :attended
            @attended_since = Time.now.utc
          end

          def ignore!
            @state = :ignored
            @attended_since = nil
          end

          def peripheral!
            @state = :peripheral
            @attended_since = nil
          end

          def salient_enough_to_capture?
            @salience >= CAPTURE_THRESHOLD
          end

          def duration
            return nil unless @state == :attended && @attended_since

            Time.now.utc - @attended_since
          end

          def to_h
            {
              id:             @id,
              name:           @name,
              domain:         @domain,
              salience:       @salience.round(4),
              state:          @state,
              attended_since: @attended_since
            }
          end
        end
      end
    end
  end
end
