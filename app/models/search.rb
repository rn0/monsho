class Search
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :query, :type => String
  field :slug, :type => String
  field :hits, :type => Integer, :default => 0

  validates_presence_of :query, :slug

  before_save :increase_hits

  def self.get query
    doc = find_or_initialize_by(:slug => query.parameterize)
    doc.query = query
    doc
  end

  def to_param
    self.query.parameterize
  end

  def get_results page
    _query = query
    Tire.search 'monsho-catalog' do
      query do
        string "name:#{_query}"
      end

      size 20
      from (page.to_i <= 1 ? 0 : (20 * (page.to_i - 1)))

      fields [:id, :name, :price, :status]
      
      facet 'category' do
        terms :category, :size => 20
      end
      facet 'manufacturer' do
        terms :manufacturer, :size => 20
      end
    end
  end
  
  private

  def increase_hits
    self.hits = hits + 1
  end
end