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
end
