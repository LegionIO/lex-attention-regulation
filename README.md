# lex-attention-regulation

Attentional resource management for LegionIO — spotlight model, zoom control, resource allocation, and salience-driven capture.

## What It Does

Models executive attention control: the agent can direct its focus to specific targets, broaden or narrow the attention beam, scan for salient events, and rest to recover depleted attention resources. Attention is treated as a depletable resource that drains during focused engagement and recovers during rest. High-salience stimuli can capture attention involuntarily.

## Core Concept: Attention as a Mode Machine

The agent cycles through five modes: `focused`, `diffuse`, `scanning`, `resting`, and `captured`. Resource drains while focused; recovers while resting. Scanning can trigger automatic capture of high-salience targets.

## Usage

```ruby
client = Legion::Extensions::AttentionRegulation::Client.new

# Register things that might need attention
client.add_attention_target(name: :security_alert, domain: :security, salience: 0.9)
client.add_attention_target(name: :routine_health_check, domain: :monitoring, salience: 0.2)

# Actively focus
target = client.most_salient_target
client.focus_attention(target_id: target[:target][:id])

# Narrow the beam for deep work
client.zoom_attention_in(amount: 0.2)

# Rest to recover resources
client.rest_attention

# Tick (drain/recover based on mode)
client.update_attention
# => { mode: :resting, resource: 0.55, zoom: 0.3 }

# Scan for high-salience events
result = client.scan_attention
# => { mode: :scanning, captured_target_id: ... }
```

## Integration

Wire into lex-tick mode transitions: enter `:resting` mode during `dormant`, `:scanning` during `sentinel`, and `:focused` during `full_active`. Pairs with lex-attention for the complete attention stack (filtering → regulation → spotlight).

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
