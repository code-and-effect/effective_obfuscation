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

    # We need to track the Maximum ID of this Table
    self.acts_as_obfuscated_opts[:max_id] ||= (self.unscoped.maximum(:id) rescue 2147483647)

    after_commit :on => :create do
      self.class.acts_as_obfuscated_opts[:max_id] = nil
    end

    # Work with Ransack if available
    if self.respond_to?(:ransacker)
      ransacker :id, :formatter => Proc.new { |v| deobfuscate(v) } { |parent| parent.table[:id] }
    end
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

      if obfuscated_id.length == 10 || obfuscated_id.to_i > 2147483647  # This is PostgreSQL Integer Max Value
        EffectiveObfuscation.show(obfuscated_id, acts_as_obfuscated_opts[:spin]).to_i
      else
        revealed = EffectiveObfuscation.show(obfuscated_id, acts_as_obfuscated_opts[:spin]).to_i
        (revealed >= 2147483647 || revealed > deobfuscated_maximum_id) ? original : revealed
      end
    end

    def deobfuscated_maximum_id
      acts_as_obfuscated_opts[:max_id] ||= (self.unscoped.maximum(:id) rescue 2147483647)
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
      super(deobfuscate(args.first))
    end

    def find_by(*args)
      if args.first.kind_of?(Hash) && args.first.key?(:id)
        args.first[:id] = deobfuscate(args.first[:id])
      end

      super(*args)
    end

    def where(*args)
      if args.first.kind_of?(Hash) && args.first.key?(:id)
        args.first[:id] = deobfuscate(args.first[:id])
      elsif args.first.class.parent == Arel::Nodes
        deobfuscate_arel!(args.first)
      end

      super(*args)
    end

    def deobfuscate_arel!(node)
      nodes = node.kind_of?(Array) ? node : [node]

      nodes.each do |node|
        if node.respond_to?(:children)
          deobfuscate_arel!(node.children)
        elsif node.respond_to?(:expr)
          deobfuscate_arel!(node.expr)
        elsif node.respond_to?(:left) && node.left.name == 'id'
          if node.right.kind_of?(Array)
            node.right = node.right.map { |id| deobfuscate(id) }
          elsif node.right.kind_of?(Integer) || node.right.kind_of?(String)
            node.right = deobfuscate(node.right)
          end
        end
      end
    end

  end

  def to_param
    self.class.obfuscate(self.id)
  end

end

