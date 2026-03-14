# frozen_string_literal: true

module Legion
  module Extensions
    module AttentionRegulation
      module Runners
        module AttentionRegulation
          include Helpers::Constants
          include Legion::Extensions::Helpers::Lex if defined?(Legion::Extensions::Helpers::Lex)

          def add_attention_target(name:, domain: :general, salience: 0.5, **)
            target = controller.add_target(name: name, domain: domain, salience: salience)
            return { success: false, reason: :limit_reached } unless target

            { success: true, target_id: target.id, name: target.name, salience: target.salience }
          end

          def focus_attention(target_id:, **)
            target = controller.focus_on(target_id: target_id)
            return { success: false, reason: :not_found } unless target

            { success: true, target_id: target.id, mode: :focused }
          end

          def defocus_attention(**)
            controller.defocus
            { success: true, mode: :diffuse }
          end

          def scan_attention(**)
            captured = controller.scan
            result = { success: true, mode: :scanning }
            result[:captured_target_id] = captured.id if captured
            result
          end

          def rest_attention(**)
            controller.rest
            { success: true, mode: :resting }
          end

          def zoom_attention_in(amount: 0.1, **)
            zoom = controller.zoom_in(amount: amount)
            { success: true, zoom: zoom.round(4) }
          end

          def zoom_attention_out(amount: 0.1, **)
            zoom = controller.zoom_out(amount: amount)
            { success: true, zoom: zoom.round(4) }
          end

          def current_attention_target(**)
            target = controller.current_target
            return { success: true, target: nil } unless target

            { success: true, target: target.to_h }
          end

          def most_salient_target(**)
            target = controller.most_salient
            return { success: true, target: nil } unless target

            { success: true, target: target.to_h }
          end

          def update_attention(**)
            controller.tick
            { success: true }.merge(controller.to_h)
          end

          def attention_regulation_stats(**)
            { success: true }.merge(controller.to_h)
          end

          private

          def controller
            @controller ||= Helpers::AttentionController.new
          end
        end
      end
    end
  end
end
