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
end
