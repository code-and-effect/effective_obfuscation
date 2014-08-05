# ActsAsObfuscated
#
# This module automatically obfuscates IDs

# Mark your model with 'acts_as_obfuscated'

module ActsAsObfuscated
  extend ActiveSupport::Concern

  module ActiveRecord
    def acts_as_obfuscated(options = nil)
      @acts_as_obfuscated_opts = options || {}

      # Guard against an improperly passed :format => '...' option
      if @acts_as_obfuscated_opts[:format]
        if @acts_as_obfuscated_opts[:format].to_s.count('#') != 10
          raise Exception.new("acts_as_obfuscated :format => '...' value must contain exactly 10 # characters. Use something like :format => '###-####-###'")
        end

        format = @acts_as_obfuscated_opts[:format].gsub('#', '0')

        if format.parameterize != format
          raise Exception.new("acts_as_obfuscated :format => '...' value must contain only String.parameterize-able characters and the # character. Use something like :format => '###-####-###'")
        end
      end

      include ::ActsAsObfuscated
    end
  end

  included do
    cattr_accessor :acts_as_obfuscated_opts
    self.acts_as_obfuscated_opts = @acts_as_obfuscated_opts

    # Set the spin based on model name if not explicity defined
    self.acts_as_obfuscated_opts[:spin] ||= (
      alphabet = Array('a'..'z')
      self.name.split('').map { |char| alphabet.index(char) }.first(12).join.to_i
    )
  end

  module ClassMethods
    def obfuscate(original)
      obfuscated = EffectiveObfuscation.hide(original, acts_as_obfuscated_opts[:spin])

      if acts_as_obfuscated_opts[:format] # Transform 1234567890 from ###-####-### into 123-4567-890 as per :format option
        acts_as_obfuscated_opts[:format].dup.tap do |formatted|
          10.times { |x| formatted.sub!('#', obfuscated[x]) }
        end
      else
        obfuscated
      end
    end

    def deobfuscate(original)
      if acts_as_obfuscated_opts[:format]
        obfuscated_id = original.to_s.delete('^0-9')
      else
        obfuscated_id = original.to_s
      end

      if obfuscated_id.length == 10
        EffectiveObfuscation.show(obfuscated_id, acts_as_obfuscated_opts[:spin]).to_i
      else
        original
      end
    end

    def relation
      super.tap { |relation| relation.extend(FinderMethods) }
    end
  end

  module FinderMethods
    def find(*args)
      super(deobfuscate(args.first))
    end

    def exists?(*args)
      super(deobfuscate(args.first))
    end

    def find_by_id(*args)
      find(*args)
    end

    def where(*args)
      if args.first.kind_of?(Hash) && args.first.key?(:id)
        args.first[:id] = deobfuscate(args.first[:id])
      end

      super(*args)
    end
  end

  def to_param
    self.class.obfuscate(self.id)
  end

end

