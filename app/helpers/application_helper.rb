module ApplicationHelper
  def format_tree(tree, &block)
    return if tree.empty?

    content_tag(:ul) do
      tree.inject("".html_safe) do |html, (node, children)|
        html << content_tag(:li) do
          (block.call node) << format_tree(children, &block)
        end
      end
    end
  end

  def link_to_category category
    return nil if (category.nil? or category.name.nil?)
    counter = (category.stats) ? category.stats.active_products.to_i : '-'
    content_tag(:a, :href => category_path(category)) do
      category.name.html_safe << " " << content_tag(:span, counter)
    end
  end

  def sortable(column, title = nil)
    title ||= column.titleize
    css_class = column == sort_column ? "current #{sort_direction}" : nil
    direction = column == sort_column && sort_direction == "asc" ? "desc" : "asc"
    link_to title, {:order => [column, direction].join('-')}, {:class => css_class}
  end

  def filter_path model, filter
    new_filters = model.filters.merge(filter)
    polymorphic_path(model, :filter => [new_filters])
  end

  def remove_filter_path model, filter
    new_filters = model.filters.dup
    new_filters.delete(filter)
    new_filters = (new_filters.empty?) ? {} : { :filter => [new_filters] }

    polymorphic_path(model, new_filters)
  end

  def active_filter? filters, filter_key
    filters.value? filter_key
  end
end
