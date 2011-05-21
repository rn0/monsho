# ! based on https://github.com/mwmitchell/rsolr/blob/master/lib/rsolr/pagination.rb
# A response module which gets mixed into the solr ["response"]["docs"] array.
module PaginatedDocSet

  attr_accessor :page, :per_page, :total_count

  def current_page
    page ? page.to_i : 1
  end

  def num_pages
    (total_count.to_f / limit_value).ceil
  end

  def limit_value
    per_page
  end
end