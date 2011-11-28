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
    logger.debug _query
    filters = @filters #(@filters) ? @filters.first : {}

    facet_filters = []
    #facet_filters = [{
    #  term: {
    #    status: true
    #  }
    #}]
    filters.each do |filter_name, filter_value|
      filter = {
        term: {
          filter_name => filter_value
        }
      }
      facet_filters.push filter
    end

    query = {
      size:   20,
      from:   ( page.to_i <= 1 ? 0 : ( 20 * ( page.to_i - 1 ) ) ),
      fields: [ :id, :name, :price, :status],

      query: {
        bool: {
          must: {
            text: {
              name: _query
            }
          },
          should: {
            term: {
              status: true
            }
          }
        },
      },

      facets: {
        category: {
          terms: {
            field: 'category',
            size: 20,
            all_terms: false
          },
        },
        manufacturer: {
          terms: {
            field: 'manufacturer',
            size: 20,
            all_terms: false
          }
        }
      }
    }
    query[:sort] = [ { column => direction } ] unless column.empty?
    unless facet_filters.empty?
      query[:filter] = { and: facet_filters }

      filter = { facet_filter: { and: facet_filters } }

      query[:facets][:manufacturer].merge!(filter)
      query[:facets][:category].merge!(filter)
    end

    logger.debug query.to_json
    query.to_json
    Tire.search 'monsho-catalog', query
  end
  
  private

  def increase_hits
    self.hits = hits + 1
  end
end