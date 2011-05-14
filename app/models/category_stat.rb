class CategoryStat
  include Mongoid::Document

  field :all_products, :type => Integer
  field :active_products, :type => Integer
  field :average_price, :type => Float
  field :min_price, :type => Float
  field :max_price, :type => Float

  embedded_in :category

  def self.calculate
    map = <<JS
function() {
  if(typeof(this.categories) == "undefined") {
    return;
  }

  var value = {
    all_products: 1,
    active_products: +this.status,
    active_price_sum: this.price,
    min_price: this.price,
    max_price: this.price
  };
  this.categories.forEach(function(c) {
    emit(c, value);
  });
}
JS
    reduce = <<JS
  function(key, values) {
    var result = {
      all_products: 0,
      active_products: 0,
      active_price_sum: 0,
      min_price: values[0].min_price,
      max_price: values[0].max_price
    };

    values.forEach(function(value) {
      result.all_products += value.all_products;
      result.active_products += value.active_products;
      if(value.active_products > 0) {
        result.active_price_sum += value.active_price_sum;
        result.min_price = (value.min_price < result.min_price) ? value.min_price : result.min_price;
        result.max_price = (value.max_price > result.max_price) ? value.max_price : result.max_price;
      }
    });

    return result;
  }
JS
  finalize = <<JS
  function(key, value) {
    var avg = value.active_price_sum / value.active_products;
    var rounded = Math.round(avg * Math.pow(10, 2)) / Math.pow(10, 2);
    value.average_price = (value.active_products > 0) ? rounded : 0;
    delete value.active_price_sum;

    if(value.active_products <= 0) {
      value.active_price_sum = 0;
      value.min_price = 0;
      value.max_price = 0;
    }

    return value;
  }
JS

    stats = Product.collection.map_reduce(map, reduce, { :finalize => finalize, :out => {:inline => 1}, :raw => true })
    stats['results'].each do |record|
      c = Category.find(record['_id'])
      c.stats = record['value']
      # TODO: error: stack to deep if :validate => true
      c.save(:validate => false)
    end
  end
end
