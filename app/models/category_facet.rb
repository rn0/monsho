class CategoryFacet
  include Mongoid::Document

  field :facet, :type => String
  field :count, :type => Integer
  field :navigable, :type => Boolean, :default => false

  embedded_in :category

  def self.calculate
    map1st = <<JS
      function() {
        if(typeof(this.category_id) == "undefined") {
          print("! undefined category_id");
          return;
        }
        if(typeof(this.description) == "undefined") {
          print("! undefined description");
          return;
        }
        var category = this.category_id;
        this.description.forEach(function(d) {
          emit({ category: category, facet: d.slug }, 1);
        });
      }
JS
    reduce1st = <<JS
      function(key, values) {
        var total = 0;
        values.forEach(function(value) {
          total += value;
        });
        return total;
      }
JS
    map2nd = <<JS
      function() {
        emit(this._id.category, { facet: this._id.facet, count: this.value });
      }
JS
    reduce2nd = <<JS
      function(key, values) {
        var total = {};
        values.forEach(function(value) {
          if(typeof total[value.facet] == "undefined") {
            total[value.facet] = 0;
          }
          total[value.facet] += value.count;
        });
        return total;
      }
JS

    Product.collection.map_reduce(map1st, reduce1st, { :out => { :replace => self.collection_name } })
    facets = Mongoid::Collection.new(self, self.collection_name).map_reduce(map2nd, reduce2nd, { :out => {:inline => 1}, :raw => true })
    facets['results'].each do |record|
      # TODO: should be non destructing update
      c = Category.find(record['_id'])
      c.facets = record['value'].reduce([]) do |acc, (facet, count)|
        acc << { facet: facet, count: count }
      end
      # TODO: error: stack to deep if :validate => true
      c.save(:validate => false)
    end
  end
end

