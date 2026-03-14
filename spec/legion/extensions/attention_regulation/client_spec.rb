# frozen_string_literal: true

RSpec.describe Legion::Extensions::AttentionRegulation::Client do
  subject(:client) { described_class.new }

  it 'full lifecycle: add targets, focus, zoom, scan, rest' do
    a = client.add_attention_target(name: 'urgent email', domain: :work, salience: 0.8)
    expect(a[:success]).to be true

    b = client.add_attention_target(name: 'background music', domain: :ambient, salience: 0.2)
    expect(b[:success]).to be true

    focus_result = client.focus_attention(target_id: a[:target_id])
    expect(focus_result[:success]).to be true
    expect(focus_result[:mode]).to eq(:focused)

    zoom_result = client.zoom_attention_in(amount: 0.2)
    expect(zoom_result[:zoom]).to be > 0.5

    current = client.current_attention_target
    expect(current[:target][:name]).to eq('urgent email')

    client.defocus_attention
    client.rest_attention

    stats = client.attention_regulation_stats
    expect(stats[:mode]).to eq(:resting)
    expect(stats[:target_count]).to eq(2)
  end

  it 'accepts an injected controller' do
    ctrl = Legion::Extensions::AttentionRegulation::Helpers::AttentionController.new
    c = described_class.new(controller: ctrl)
    c.add_attention_target(name: 'injected', salience: 0.5)
    expect(ctrl.to_h[:target_count]).to eq(1)
  end

  it 'captures high-salience target during scan' do
    client.add_attention_target(name: 'alarm', domain: :safety, salience: 0.9)
    result = client.scan_attention
    expect(result[:captured_target_id]).not_to be_nil
  end

  it 'resource drains when focused and recovers when resting' do
    t = client.add_attention_target(name: 'work', salience: 0.5)
    client.focus_attention(target_id: t[:target_id])
    initial = client.attention_regulation_stats[:resource]

    5.times { client.update_attention }
    drained = client.attention_regulation_stats[:resource]
    expect(drained).to be < initial

    client.rest_attention
    client.update_attention
    recovered = client.attention_regulation_stats[:resource]
    expect(recovered).to be > drained
  end
end
