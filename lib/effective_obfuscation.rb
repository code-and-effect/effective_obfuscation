require 'scatter_swap'
require 'effective_obfuscation/engine'
require 'effective_obfuscation/version'

module EffectiveObfuscation
  def self.hide(id, spin)
    ::ScatterSwap.hash(id, spin)
  end

  def self.show(id, spin)
    ::ScatterSwap.reverse_hash(id, spin).to_i
  end

  def self.extend_klass?
    return false if Gem::Version.new(Rails.version) < Gem::Version.new('4.2')
    return true if Gem::Version.new(Rails.version) >= Gem::Version.new('5')
    false
  end

  def self.extend_relation?
    return true if Gem::Version.new(Rails.version) < Gem::Version.new('4.2')
    return true if Gem::Version.new(Rails.version) >= Gem::Version.new('5')
    false
  end

end
