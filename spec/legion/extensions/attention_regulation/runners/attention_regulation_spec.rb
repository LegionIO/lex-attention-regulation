# frozen_string_literal: true

RSpec.describe Legion::Extensions::AttentionRegulation::Runners::AttentionRegulation do
  let(:runner) do
    obj = Object.new
    obj.extend(described_class)
    obj
  end

  describe '#add_attention_target' do
    it 'creates a target and returns success' do
      result = runner.add_attention_target(name: 'email', domain: :work, salience: 0.4)
      expect(result[:success]).to be true
      expect(result[:target_id]).to be_a(Symbol)
      expect(result[:name]).to eq('email')
    end

    it 'returns failure when limit is reached' do
      30.times { |i| runner.add_attention_target(name: "target #{i}", salience: 0.3) }
      result = runner.add_attention_target(name: 'overflow', salience: 0.5)
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:limit_reached)
    end
  end

  describe '#focus_attention' do
    it 'focuses on a known target' do
      created = runner.add_attention_target(name: 'task', salience: 0.5)
      result = runner.focus_attention(target_id: created[:target_id])
      expect(result[:success]).to be true
      expect(result[:mode]).to eq(:focused)
    end

    it 'returns failure for unknown target' do
      result = runner.focus_attention(target_id: :bogus)
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:not_found)
    end
  end

  describe '#defocus_attention' do
    it 'defocuses and returns success' do
      result = runner.defocus_attention
      expect(result[:success]).to be true
      expect(result[:mode]).to eq(:diffuse)
    end
  end

  describe '#scan_attention' do
    it 'returns success with scanning mode when nothing captures' do
      runner.add_attention_target(name: 'low', salience: 0.2)
      result = runner.scan_attention
      expect(result[:success]).to be true
      expect(result[:mode]).to eq(:scanning)
    end

    it 'includes captured_target_id when a target is captured' do
      runner.add_attention_target(name: 'urgent', salience: 0.9)
      result = runner.scan_attention
      expect(result[:success]).to be true
      expect(result[:captured_target_id]).to be_a(Symbol)
    end
  end

  describe '#rest_attention' do
    it 'returns success with resting mode' do
      result = runner.rest_attention
      expect(result[:success]).to be true
      expect(result[:mode]).to eq(:resting)
    end
  end

  describe '#zoom_attention_in' do
    it 'increases zoom and returns success' do
      result = runner.zoom_attention_in(amount: 0.1)
      expect(result[:success]).to be true
      expect(result[:zoom]).to be > 0.5
    end

    it 'uses default amount' do
      result = runner.zoom_attention_in
      expect(result[:success]).to be true
    end
  end

  describe '#zoom_attention_out' do
    it 'decreases zoom and returns success' do
      result = runner.zoom_attention_out(amount: 0.1)
      expect(result[:success]).to be true
      expect(result[:zoom]).to be < 0.5
    end

    it 'uses default amount' do
      result = runner.zoom_attention_out
      expect(result[:success]).to be true
    end
  end

  describe '#current_attention_target' do
    it 'returns target: nil when not focused' do
      result = runner.current_attention_target
      expect(result[:success]).to be true
      expect(result[:target]).to be_nil
    end

    it 'returns current target when focused' do
      created = runner.add_attention_target(name: 'active', salience: 0.5)
      runner.focus_attention(target_id: created[:target_id])
      result = runner.current_attention_target
      expect(result[:success]).to be true
      expect(result[:target]).to be_a(Hash)
      expect(result[:target][:name]).to eq('active')
    end
  end

  describe '#most_salient_target' do
    it 'returns target: nil when no targets' do
      result = runner.most_salient_target
      expect(result[:success]).to be true
      expect(result[:target]).to be_nil
    end

    it 'returns the most salient target' do
      runner.add_attention_target(name: 'low', salience: 0.2)
      runner.add_attention_target(name: 'high', salience: 0.8)
      result = runner.most_salient_target
      expect(result[:success]).to be true
      expect(result[:target][:name]).to eq('high')
    end
  end

  describe '#update_attention' do
    it 'ticks and returns stats' do
      result = runner.update_attention
      expect(result[:success]).to be true
      expect(result).to include(:mode, :zoom, :resource, :resource_label)
    end
  end

  describe '#attention_regulation_stats' do
    it 'returns stats hash' do
      result = runner.attention_regulation_stats
      expect(result[:success]).to be true
      expect(result).to include(:mode, :target_count)
    end
  end
end
