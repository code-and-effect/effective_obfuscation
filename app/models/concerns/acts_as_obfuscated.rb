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

    after_create do
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

    # If rescue_with_original_id is set to true the original ID will be returned when its Obfuscated Id is not found
    #
    # We use this as the default behaviour on everything except Class.find()
    def deobfuscate(original, rescue_with_original_id = true)
      if original.kind_of?(Array)
        return original.map { |value| deobfuscate(value, true) } # Always rescue with original ID
      elsif !(original.kind_of?(Integer) || original.kind_of?(String))
        return original
      end

      # Remove any non-digit formatting characters, and only consider the first 10 digits
      obfuscated_id = original.to_s.delete('^0-9').first(10)

      # 2147483647 is PostgreSQL's Integer Max Value.  If we return a value higher than this, we get weird DB errors
      revealed = [EffectiveObfuscation.show(obfuscated_id, acts_as_obfuscated_opts[:spin]).to_i, 2147483647].min

      if rescue_with_original_id && (revealed >= 2147483647 || revealed > deobfuscated_maximum_id)
        original
      else
        revealed
      end
    end

    def deobfuscator(left)
      acts_as_obfuscated_opts[:deobfuscators] ||= Hash.new().tap do |deobfuscators|
        deobfuscators['id'] = Proc.new { |right| self.deobfuscate(right) }

        reflect_on_all_associations(:belongs_to).each do |reflection|
          if reflection.klass.respond_to?(:deobfuscate)
            deobfuscators[reflection.foreign_key] = Proc.new { |right| reflection.klass.deobfuscate(right) }
          end
        end
      end

      acts_as_obfuscated_opts[:deobfuscators][left.to_s]
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
      super(deobfuscate(args.first, false))
    end

    def exists?(*args)
      super(deobfuscate(args.first))
    end

    def find_by_id(*args)
      super(deobfuscate(args.first))
    end

    def find_by(*args)
      if args.first.kind_of?(Hash)
        args.first.each do |left, right|
          next unless (d = deobfuscator(left))
          args.first[left] = d.call(right)
        end
      end

      super(*args)
    end

    def where(*args)
      if args.first.kind_of?(Hash)
        args.first.each do |left, right|
          next unless (d = deobfuscator(left))
          args.first[left] = d.call(right)
        end
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
        elsif node.respond_to?(:left)
          next unless (d = deobfuscator(node.left.name))
          node.right = d.call(node.right) unless (node.right.kind_of?(String) && node.right.include?('$'))
        end
      end
    end
  end

  def to_param
    self.class.obfuscate(self.id)
  end

end

