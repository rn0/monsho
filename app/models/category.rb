class Category
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Tree
  include Mongoid::Tree::Traversal

  field :name, :type => String
  
  validates_presence_of :name
  validates_associated :parent, :children

  embeds_one :stats, class_name: 'CategoryStat'
  #embeds_many :facets, class_name: 'CategoryFacet'
  has_many :products

  @@spacer = '&mdash;'.html_safe
  cattr_accessor :spacer
  attr_accessor :filters

  INVALID_FACETS = ['www', 'Kod Producenta', 'Informacje dodatkowe', 'Opis']

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

  def facet_fields
    # TODO: cache
    products.distinct('description.name') - INVALID_FACETS
  end

  def get_results page, column, direction
    current_filters = [
      { term: { status: true } },
      { term: { category: name } }
    ]

    @filters.each do |filter_name, filter_value|
      filter = { :term => { filter_name => filter_value } }
      current_filters.push filter
    end

    query = {
      size:   20,
      from:   ( page.to_i <= 1 ? 0 : ( 20 * ( page.to_i - 1 ) ) ),
      fields: [ :id, :name, :price, :status],

      query: {
        constant_score: {
          filter: {
            and: current_filters
          }
        }
      },
      facets: {
        manufacturer: {
          terms: {
            field: 'manufacturer',
            size: 2147483647
          }
        }
      }
    }

    query[:sort] = [ { column => direction } ] unless column.empty?

    facet_fields.each do |field|
      field = field.to_slug.normalize.to_s
      query[:facets][field] = {
        terms: {
          field: field,
          size:  2147483647
        }
      }
    end
    #logger.debug query.to_json
    Tire.search 'monsho-catalog', query
  end
end
