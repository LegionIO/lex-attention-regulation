# frozen_string_literal: true

RSpec.describe Legion::Extensions::AttentionRegulation::Helpers::AttentionTarget do
  subject(:target) do
    described_class.new(id: :target_one, name: 'urgent task', domain: :work, salience: 0.6)
  end

  describe '#initialize' do
    it 'sets id, name, domain, salience' do
      expect(target.id).to eq(:target_one)
      expect(target.name).to eq('urgent task')
      expect(target.domain).to eq(:work)
      expect(target.salience).to eq(0.6)
    end

    it 'starts in :peripheral state' do
      expect(target.state).to eq(:peripheral)
    end

    it 'starts with nil attended_since' do
      expect(target.attended_since).to be_nil
    end

    it 'clamps salience to 0..1' do
      t = described_class.new(id: :x, name: 'x', salience: 2.5)
      expect(t.salience).to eq(1.0)
    end

    it 'clamps salience floor to 0' do
      t = described_class.new(id: :x, name: 'x', salience: -0.5)
      expect(t.salience).to eq(0.0)
    end
  end

  describe '#attend!' do
    it 'sets state to :attended' do
      target.attend!
      expect(target.state).to eq(:attended)
    end

    it 'records attended_since timestamp' do
      target.attend!
      expect(target.attended_since).to be_a(Time)
    end
  end

  describe '#ignore!' do
    it 'sets state to :ignored' do
      target.attend!
      target.ignore!
      expect(target.state).to eq(:ignored)
    end

    it 'clears attended_since' do
      target.attend!
      target.ignore!
      expect(target.attended_since).to be_nil
    end
  end

  describe '#peripheral!' do
    it 'sets state to :peripheral' do
      target.attend!
      target.peripheral!
      expect(target.state).to eq(:peripheral)
    end

    it 'clears attended_since' do
      target.attend!
      target.peripheral!
      expect(target.attended_since).to be_nil
    end
  end

  describe '#salient_enough_to_capture?' do
    it 'returns false when salience is below threshold' do
      t = described_class.new(id: :x, name: 'x', salience: 0.5)
      expect(t.salient_enough_to_capture?).to be false
    end

    it 'returns true when salience meets threshold' do
      t = described_class.new(id: :x, name: 'x', salience: 0.7)
      expect(t.salient_enough_to_capture?).to be true
    end

    it 'returns true when salience exceeds threshold' do
      t = described_class.new(id: :x, name: 'x', salience: 0.9)
      expect(t.salient_enough_to_capture?).to be true
    end
  end

  describe '#duration' do
    it 'returns nil when not attended' do
      expect(target.duration).to be_nil
    end

    it 'returns nil when ignored' do
      target.attend!
      target.ignore!
      expect(target.duration).to be_nil
    end

    it 'returns elapsed time when attended' do
      target.attend!
      sleep(0.01)
      expect(target.duration).to be_a(Float)
      expect(target.duration).to be > 0
    end
  end

  describe '#to_h' do
    it 'returns a hash with expected keys' do
      h = target.to_h
      expect(h).to include(:id, :name, :domain, :salience, :state, :attended_since)
    end

    it 'rounds salience to 4 decimal places' do
      t = described_class.new(id: :x, name: 'x', salience: 0.123456789)
      expect(t.to_h[:salience]).to eq(0.1235)
    end
  end
end
