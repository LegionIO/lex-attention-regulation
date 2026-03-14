# frozen_string_literal: true

require_relative 'lib/legion/extensions/attention_regulation/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-attention-regulation'
  spec.version       = Legion::Extensions::AttentionRegulation::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'Attentional resource management for LegionIO'
  spec.description   = 'Attention regulation engine for LegionIO — ' \
                       'spotlight model, zoom control, resource allocation, and salience-driven capture'
  spec.homepage      = 'https://github.com/LegionIO/lex-attention-regulation'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']      = spec.homepage
  spec.metadata['source_code_uri']   = spec.homepage
  spec.metadata['documentation_uri'] = "#{spec.homepage}/blob/master/README.md"
  spec.metadata['changelog_uri']     = "#{spec.homepage}/blob/master/CHANGELOG.md"
  spec.metadata['bug_tracker_uri']   = "#{spec.homepage}/issues"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files         = Dir['lib/**/*']
  spec.require_paths = ['lib']
end
