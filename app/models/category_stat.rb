class CategoryStat
  include Mongoid::Document

  field :value, :type => Hash

  belongs_to :category

  def self.calculate
    map = <<JS
function() {
  if(typeof(this.categories) == "undefined") {
    return;
  }

  var value = {
    all: 1,
    active: +this.status,
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
      all: 0,
      active: 0,
      active_price_sum: 0,
      min_price: values[0].min_price,
      max_price: values[0].max_price
    };

    values.forEach(function(value) {
      result.all += value.all;
      result.active += value.active;
      if(value.active > 0) {
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
    value.active_price_avg = (value.active > 0) ? value.active_price_sum / value.active : 0;
    delete value.active_price_sum;

    if(value.active <= 0) {
      value.active_price_sum = 0;
      value.min_price = 0;
      value.max_price = 0;
    }

    return value;
  }
JS

    Product.collection.map_reduce(map, reduce, { :finalize => finalize, :out => { :replace => self.collection_name } })
  end
end
