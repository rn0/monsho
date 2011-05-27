module Tire
  module Results
    module Pagination
      alias :num_pages :total_pages

      def limit_value
        @options[:per_page] ? @options[:per_page].to_i : 10
      end

    end
  end
end