class Category
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Tree
  include Mongoid::Tree::Traversal

  field :name, :type => String
  
  validates_presence_of :name
  validates_associated :parent, :children

  has_many :products
  has_one :category_stat, :foreign_key => "_id"

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

  def path
    self.ancestors_and_self.collect(&:name).join(' / ')
  end
end
