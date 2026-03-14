# frozen_string_literal: true

RSpec.describe Legion::Extensions::AttentionRegulation::Helpers::AttentionController do
  subject(:ctrl) { described_class.new }

  describe '#initialize' do
    it 'starts in :diffuse mode' do
      expect(ctrl.to_h[:mode]).to eq(:diffuse)
    end

    it 'starts with full resource' do
      expect(ctrl.to_h[:resource]).to eq(1.0)
    end

    it 'starts with default zoom' do
      expect(ctrl.to_h[:zoom]).to eq(0.5)
    end

    it 'starts with zero targets' do
      expect(ctrl.to_h[:target_count]).to eq(0)
    end
  end

  describe '#add_target' do
    it 'adds a target and returns it' do
      target = ctrl.add_target(name: 'inbox', domain: :work, salience: 0.4)
      expect(target).to be_a(Legion::Extensions::AttentionRegulation::Helpers::AttentionTarget)
      expect(target.name).to eq('inbox')
    end

    it 'increments target count' do
      ctrl.add_target(name: 'first', salience: 0.3)
      ctrl.add_target(name: 'second', salience: 0.5)
      expect(ctrl.to_h[:target_count]).to eq(2)
    end

    it 'assigns unique ids' do
      t1 = ctrl.add_target(name: 'a', salience: 0.3)
      t2 = ctrl.add_target(name: 'b', salience: 0.4)
      expect(t1.id).not_to eq(t2.id)
    end

    it 'returns nil when limit is reached' do
      30.times { |i| ctrl.add_target(name: "target #{i}", salience: 0.3) }
      result = ctrl.add_target(name: 'overflow', salience: 0.5)
      expect(result).to be_nil
    end
  end

  describe '#focus_on' do
    let(:target) { ctrl.add_target(name: 'focus me', salience: 0.5) }

    it 'sets mode to :focused' do
      ctrl.focus_on(target_id: target.id)
      expect(ctrl.to_h[:mode]).to eq(:focused)
    end

    it 'sets the current target' do
      ctrl.focus_on(target_id: target.id)
      expect(ctrl.current_target).to eq(target)
    end

    it 'marks the target as attended' do
      ctrl.focus_on(target_id: target.id)
      expect(target.state).to eq(:attended)
    end

    it 'returns nil for unknown target' do
      result = ctrl.focus_on(target_id: :nonexistent)
      expect(result).to be_nil
    end

    it 'marks previous target as peripheral when switching focus' do
      t1 = ctrl.add_target(name: 'first', salience: 0.4)
      t2 = ctrl.add_target(name: 'second', salience: 0.5)
      ctrl.focus_on(target_id: t1.id)
      ctrl.focus_on(target_id: t2.id)
      expect(t1.state).to eq(:peripheral)
      expect(t2.state).to eq(:attended)
    end
  end

  describe '#defocus' do
    it 'sets mode to :diffuse' do
      target = ctrl.add_target(name: 'x', salience: 0.4)
      ctrl.focus_on(target_id: target.id)
      ctrl.defocus
      expect(ctrl.to_h[:mode]).to eq(:diffuse)
    end

    it 'clears current target' do
      target = ctrl.add_target(name: 'x', salience: 0.4)
      ctrl.focus_on(target_id: target.id)
      ctrl.defocus
      expect(ctrl.current_target).to be_nil
    end

    it 'marks previously attended target as peripheral' do
      target = ctrl.add_target(name: 'x', salience: 0.4)
      ctrl.focus_on(target_id: target.id)
      ctrl.defocus
      expect(target.state).to eq(:peripheral)
    end
  end

  describe '#scan' do
    it 'sets mode to :scanning' do
      ctrl.scan
      expect(ctrl.to_h[:mode]).to eq(:scanning)
    end

    it 'captures a high-salience target automatically' do
      ctrl.add_target(name: 'urgent', salience: 0.9)
      ctrl.scan
      expect(ctrl.to_h[:mode]).to eq(:captured)
    end

    it 'does not capture when no target meets threshold' do
      ctrl.add_target(name: 'low', salience: 0.3)
      ctrl.scan
      expect(ctrl.to_h[:mode]).to eq(:scanning)
    end
  end

  describe '#rest' do
    it 'sets mode to :resting' do
      ctrl.rest
      expect(ctrl.to_h[:mode]).to eq(:resting)
    end

    it 'clears current target' do
      t = ctrl.add_target(name: 'x', salience: 0.4)
      ctrl.focus_on(target_id: t.id)
      ctrl.rest
      expect(ctrl.current_target).to be_nil
    end
  end

  describe '#zoom_in' do
    it 'increases zoom' do
      original = ctrl.to_h[:zoom]
      ctrl.zoom_in(amount: 0.2)
      expect(ctrl.to_h[:zoom]).to be > original
    end

    it 'clamps zoom at ceiling' do
      ctrl.zoom_in(amount: 2.0)
      expect(ctrl.to_h[:zoom]).to eq(1.0)
    end
  end

  describe '#zoom_out' do
    it 'decreases zoom' do
      original = ctrl.to_h[:zoom]
      ctrl.zoom_out(amount: 0.2)
      expect(ctrl.to_h[:zoom]).to be < original
    end

    it 'clamps zoom at floor' do
      ctrl.zoom_out(amount: 2.0)
      expect(ctrl.to_h[:zoom]).to eq(0.1)
    end
  end

  describe '#check_capture' do
    it 'captures the most salient unattended target above threshold' do
      ctrl.add_target(name: 'medium', salience: 0.75)
      ctrl.add_target(name: 'high', salience: 0.95)
      result = ctrl.check_capture
      expect(result).not_to be_nil
      expect(result.salience).to eq(0.95)
    end

    it 'returns nil when no target is salient enough' do
      ctrl.add_target(name: 'low', salience: 0.2)
      expect(ctrl.check_capture).to be_nil
    end

    it 'returns nil when resource is too low' do
      ctrl.add_target(name: 'urgent', salience: 0.9)
      # set resource below the 0.3 capture threshold directly
      ctrl.instance_variable_set(:@resource, 0.1)
      expect(ctrl.check_capture).to be_nil
    end

    it 'does not capture an already attended target' do
      t = ctrl.add_target(name: 'urgent', salience: 0.9)
      ctrl.focus_on(target_id: t.id)
      # attended target should not self-capture
      result = ctrl.check_capture
      expect(result).to be_nil
    end
  end

  describe '#current_target' do
    it 'returns nil when not focused' do
      expect(ctrl.current_target).to be_nil
    end

    it 'returns the focused target' do
      t = ctrl.add_target(name: 'active', salience: 0.5)
      ctrl.focus_on(target_id: t.id)
      expect(ctrl.current_target).to eq(t)
    end
  end

  describe '#most_salient' do
    it 'returns the target with highest salience' do
      ctrl.add_target(name: 'low', salience: 0.2)
      ctrl.add_target(name: 'high', salience: 0.8)
      ctrl.add_target(name: 'mid', salience: 0.5)
      expect(ctrl.most_salient.name).to eq('high')
    end

    it 'returns nil when no targets exist' do
      expect(ctrl.most_salient).to be_nil
    end
  end

  describe '#attended_targets' do
    it 'returns only attended targets' do
      t1 = ctrl.add_target(name: 'a', salience: 0.5)
      ctrl.add_target(name: 'b', salience: 0.4)
      ctrl.focus_on(target_id: t1.id)
      expect(ctrl.attended_targets.size).to eq(1)
      expect(ctrl.attended_targets.first).to eq(t1)
    end
  end

  describe '#peripheral_targets' do
    it 'returns targets in :peripheral state' do
      ctrl.add_target(name: 'a', salience: 0.3)
      ctrl.add_target(name: 'b', salience: 0.4)
      expect(ctrl.peripheral_targets.size).to eq(2)
    end
  end

  describe '#tick' do
    it 'drains resource when focused' do
      t = ctrl.add_target(name: 'x', salience: 0.4)
      ctrl.focus_on(target_id: t.id)
      original = ctrl.to_h[:resource]
      ctrl.tick
      expect(ctrl.to_h[:resource]).to be < original
    end

    it 'recovers resource when resting' do
      # first drain a bit
      t = ctrl.add_target(name: 'x', salience: 0.4)
      ctrl.focus_on(target_id: t.id)
      5.times { ctrl.tick }
      ctrl.rest
      before_rest = ctrl.to_h[:resource]
      ctrl.tick
      expect(ctrl.to_h[:resource]).to be > before_rest
    end

    it 'does not change resource in diffuse mode' do
      original = ctrl.to_h[:resource]
      ctrl.tick
      expect(ctrl.to_h[:resource]).to eq(original)
    end

    it 'triggers capture during scan tick' do
      ctrl.add_target(name: 'urgent', salience: 0.9)
      ctrl.scan
      # scan already triggered capture in #scan, let's reset and test tick-triggered
      ctrl2 = described_class.new
      ctrl2.add_target(name: 'urgent', salience: 0.9)
      # put in scanning mode without triggering capture (no target above threshold yet)
      ctrl2.instance_variable_set(:@mode, :scanning)
      ctrl2.tick
      expect(ctrl2.to_h[:mode]).to eq(:captured)
    end
  end

  describe '#resource_label' do
    it 'returns :abundant for full resource' do
      expect(ctrl.resource_label).to eq(:abundant)
    end

    it 'returns a symbol' do
      expect(ctrl.resource_label).to be_a(Symbol)
    end
  end

  describe '#to_h' do
    it 'returns expected keys' do
      expect(ctrl.to_h).to include(
        :mode, :zoom, :resource, :resource_label,
        :current_target_id, :target_count, :attended_count, :peripheral_count
      )
    end
  end
end
