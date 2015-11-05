require 'scatter_swap'
require "effective_obfuscation/engine"

module EffectiveObfuscation
  def self.hide(id, spin)
    ::ScatterSwap.hash(id, spin)
  end

  def self.show(id, spin)
    ::ScatterSwap.reverse_hash(id, spin).to_i
  end
end
