class Category
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Tree
  include Mongoid::Tree::Traversal

  field :name, :type => String
  
  validates_presence_of :name
  validates_associated :parent, :children

  embeds_one :stats, class_name: 'CategoryStat'
  has_many :products

  @@spacer = '&mdash;'.html_safe
  cattr_accessor :spacer

  def self.tree
    nodes = []
    self.traverse(:breadth_first) do |node|
      # TODO: what if node.name contains unsafe content?
      nodes.push [ "#{self.spacer * node.depth} #{node.name}".html_safe, node.id ]
    end
    nodes
  end

  def tree_by_path
    Rails.logger.debug "tree_by_path"
    ids = if parent_ids.empty?
            [id]
          else
            parent_ids
          end
    
    base_class.where(:parent_id.in => [nil, *ids])
  end

  def self.arrange
    arrange_nodes all
  end

  def self.arrange_nodes(nodes)
    nodes.inject({}) do |arranged_nodes, node|
      ret = node.parent_ids.inject(arranged_nodes) do |insertion_point, ancestor_id|
        insertion_point.each do |parent, children|
          # Change the insertion point to children if node is a descendant of this parent
          insertion_point = children if ancestor_id == parent.id
        end
        insertion_point
      end
      ret[node] = {}
      arranged_nodes
    end
  end

  def path
    self.ancestors_and_self.collect(&:name).join(' / ')
  end
end
