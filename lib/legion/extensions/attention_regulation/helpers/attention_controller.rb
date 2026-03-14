# frozen_string_literal: true

module Legion
  module Extensions
    module AttentionRegulation
      module Helpers
        class AttentionController
          include Constants

          def initialize
            @targets           = {}
            @current_target_id = nil
            @zoom              = DEFAULT_ZOOM
            @resource          = DEFAULT_RESOURCE
            @mode              = :diffuse
            @counter           = 0
            @history           = []
          end

          def add_target(name:, domain: :general, salience: 0.5)
            return nil if @targets.size >= MAX_TARGETS

            id = :"target_#{@counter}"
            @counter += 1
            target = AttentionTarget.new(id: id, name: name, domain: domain, salience: salience)
            @targets[id] = target
            target
          end

          def focus_on(target_id:)
            target = @targets[target_id]
            return nil unless target

            defocus_current_target
            @current_target_id = target_id
            @mode = :focused
            target.attend!
            record_history(:focus, target_id)
            target
          end

          def defocus
            defocus_current_target
            @current_target_id = nil
            @mode = :diffuse
            record_history(:defocus, nil)
            true
          end

          def scan
            @mode = :scanning
            record_history(:scan, nil)
            check_capture
          end

          def rest
            @mode = :resting
            @current_target_id = nil
            record_history(:rest, nil)
            true
          end

          def zoom_in(amount: 0.1)
            @zoom = (@zoom + amount.to_f).clamp(ZOOM_FLOOR, ZOOM_CEILING)
            @zoom
          end

          def zoom_out(amount: 0.1)
            @zoom = (@zoom - amount.to_f).clamp(ZOOM_FLOOR, ZOOM_CEILING)
            @zoom
          end

          def check_capture
            return nil unless @resource > 0.3

            candidate = @targets.values
                                .select { |t| t.state != :attended && t.salient_enough_to_capture? }
                                .max_by(&:salience)
            return nil unless candidate

            focus_on(target_id: candidate.id)
            @mode = :captured
            record_history(:captured, candidate.id)
            candidate
          end

          def current_target
            return nil unless @current_target_id

            @targets[@current_target_id]
          end

          def most_salient
            @targets.values.max_by(&:salience)
          end

          def attended_targets
            @targets.values.select { |t| t.state == :attended }
          end

          def peripheral_targets
            @targets.values.select { |t| t.state == :peripheral }
          end

          def tick
            case @mode
            when :focused, :captured
              @resource = (@resource - RESOURCE_DRAIN).clamp(RESOURCE_FLOOR, RESOURCE_CEILING)
            when :resting
              @resource = (@resource + RESOURCE_RECOVERY).clamp(RESOURCE_FLOOR, RESOURCE_CEILING)
            end

            check_capture if @mode == :scanning
          end

          def resource_label
            RESOURCE_LABELS.each { |range, lbl| return lbl if range.cover?(@resource) }
            :depleted
          end

          def to_h
            {
              mode:              @mode,
              zoom:              @zoom.round(4),
              resource:          @resource.round(4),
              resource_label:    resource_label,
              current_target_id: @current_target_id,
              target_count:      @targets.size,
              attended_count:    attended_targets.size,
              peripheral_count:  peripheral_targets.size,
              history_count:     @history.size
            }
          end

          private

          def defocus_current_target
            return unless @current_target_id

            current = @targets[@current_target_id]
            current&.peripheral!
          end

          def record_history(action, target_id)
            entry = { action: action, target_id: target_id, at: Time.now.utc }
            @history << entry
            @history.shift if @history.size > MAX_HISTORY
          end
        end
      end
    end
  end
end
