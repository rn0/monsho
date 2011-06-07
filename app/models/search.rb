class Search
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :query, :type => String
  field :slug, :type => String
  field :hits, :type => Integer, :default => 0

  validates_presence_of :query, :slug

  before_save :increase_hits

  attr_accessor :filters

  def self.get query
    doc = find_or_initialize_by(:slug => query.parameterize)
    doc.query = query
    doc
  end

  def to_param
    self.query.parameterize
  end

  def get_results page, column, direction
    _query = query
    filters = @filters #(@filters) ? @filters.first : {}
    
    facet_filter = []
    filters.each do |filter_name, filter_value|
      filter = {
        :term => {
          filter_name => filter_value
        }
      }
      facet_filter.push filter
    end

    facet_options = { :size => 20 }
    unless filters.empty?
      facet_options.merge!(:facet_filter => { :and => facet_filter })
    end

    Tire.search 'monsho-catalog' do
      query do
        string "name:#{_query}"
      end

      size 20
      from (page.to_i <= 1 ? 0 : (20 * (page.to_i - 1)))

      fields [:id, :name, :price, :status]

      unless column.empty?
        sort do
          send column, direction
        end
      end

      unless filters.empty?
        filter :and, facet_filter
      end
      
      facet 'category' do
        terms :category, facet_options
      end
      facet 'manufacturer' do
        terms :manufacturer, facet_options
      end
    end
  end
  
  private

  def increase_hits
    self.hits = hits + 1
  end
end