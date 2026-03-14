# lex-attention-regulation

**Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Attention regulation engine for LegionIO — spotlight model, zoom control, resource allocation, and salience-driven capture. Models the executive control of attention: the agent can actively direct focus, zoom in or out, scan for salience, rest to recover attention resources, and be captured by high-salience stimuli.

## Gem Info

- **Gem name**: `lex-attention-regulation`
- **Version**: `0.1.0`
- **Module**: `Legion::Extensions::AttentionRegulation`
- **Ruby**: `>= 3.4`
- **License**: MIT

## File Structure

```
lib/legion/extensions/attention_regulation/
  (no top-level module file — version.rb only at root of namespace)
  version.rb                      # VERSION = '0.1.0'
  client.rb                       # Client wrapper
  helpers/
    constants.rb                  # Resource limits, modes, thresholds, labels
    attention_target.rb           # AttentionTarget value object
    attention_controller.rb       # AttentionController — mode/zoom/resource management
  runners/
    attention_regulation.rb       # Runner module with 11 public methods
spec/
  (spec files)
```

## Key Constants

```ruby
MAX_TARGETS      = 30
MAX_HISTORY      = 200
DEFAULT_RESOURCE = 1.0
RESOURCE_FLOOR   = 0.05
RESOURCE_CEILING = 1.0
RESOURCE_DRAIN   = 0.02   # per tick while focused
RESOURCE_RECOVERY = 0.03  # per tick while resting

CAPTURE_THRESHOLD = 0.7   # salience above this can capture attention
DEFAULT_ZOOM      = 0.5
ZOOM_FLOOR        = 0.1
ZOOM_CEILING      = 1.0

ATTENTION_MODES = %i[focused diffuse scanning resting captured]
TARGET_STATES   = %i[attended peripheral ignored]

RESOURCE_LABELS = {
  (0.8..) => :abundant, (0.6...0.8) => :adequate, (0.4...0.6) => :moderate,
  (0.2...0.4) => :low, (..0.2) => :depleted
}
```

## Runners

### `Runners::AttentionRegulation`

Includes `Helpers::Constants` directly. All methods delegate to a private `@controller` (`Helpers::AttentionController` instance).

- `add_attention_target(name:, domain: :general, salience: 0.5)` — register a target for potential attention
- `focus_attention(target_id:)` — enter `:focused` mode on a specific target; drains resources
- `defocus_attention` — exit focused mode, enter `:diffuse`
- `scan_attention` — enter `:scanning` mode; returns captured target if one exceeds `CAPTURE_THRESHOLD`
- `rest_attention` — enter `:resting` mode; recovers attention resources
- `zoom_attention_in(amount: 0.1)` — narrow the attention beam (lower zoom = more focused)
- `zoom_attention_out(amount: 0.1)` — broaden the attention beam
- `current_attention_target` — current focused target or nil
- `most_salient_target` — highest-salience registered target
- `update_attention` — tick cycle: apply resource drain/recovery based on mode
- `attention_regulation_stats` — full state hash including mode, resource, zoom, target count

## Helpers

### `Helpers::AttentionController`
Core engine. Manages `@mode`, `@zoom`, `@resource`, `@current_target`, and `@targets` hash. `scan` checks all targets for those above `CAPTURE_THRESHOLD` and transitions to `:captured` mode if found. `tick` applies `RESOURCE_DRAIN` (focused) or `RESOURCE_RECOVERY` (resting) each call.

### `Helpers::AttentionTarget`
Value object: id, name, domain, salience, state, created_at. State: `:attended`, `:peripheral`, `:ignored`.

## Integration Points

No actor defined — callers must invoke `update_attention` for resource drain/recovery. Complements lex-attention (signal filtering) and lex-attention-spotlight (spotlight geometry): this extension manages the executive control layer (modes, resources) while spotlight manages the geometric model (beam width, intensity). Wire into lex-tick's sensing phase: `rest_attention` during dormant mode recovers resources; `scan_attention` during sentinel mode watches for salient events.

## Development Notes

- Note: no top-level `attention_regulation.rb` module file — the namespace is partially defined; `AttentionRegulation` module is established via `version.rb` and individual files
- Runner includes `Helpers::Constants` via `include Helpers::Constants` (not a conditional guard as in other extensions)
- `scan` captures the first target above `CAPTURE_THRESHOLD`, not necessarily the most salient
- Resource floor of 0.05 prevents complete depletion — there is always some minimal attention available
