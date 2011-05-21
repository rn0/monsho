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
    response = RSolr.connect.paginate page || 1, 20, 'select', :params => {
      :q => query,
      :fl => 'id, name, status, price',
      :facet => true,
      'facet.mincount' => 1,
      'facet.field' => ['category', 'manufacturer'],
    }
    docs = response['response']['docs'].extend ::PaginatedDocSet
    docs.total_count = response['response']['numFound']
    docs.page = page
    info = {
      :numFound => response['response']['numFound'],
      :QTime => response['responseHeader']['QTime']
    }
    [info, docs, response['facet_counts']['facet_fields']]
  end
  
  private

  def increase_hits
    self.hits = hits + 1
  end
end