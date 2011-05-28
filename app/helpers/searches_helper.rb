module SearchesHelper
  def search_filter_path search, filter
    new_filters = search.filters.merge(filter)
    search_path(search, :filter => [new_filters])
  end

  def remove_search_filter_path search, filter
    new_filters = search.filters.dup
    new_filters.delete(filter)
    new_filters = (new_filters.empty?) ? nil : { :filter => [new_filters] }

    search_path(search, new_filters)
  end

  def active_filter? filters, filter_key
    filters.value? filter_key
  end
end
