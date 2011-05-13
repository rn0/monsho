Factory.define :product do |f|
  f.name 'Test product'
  f.net_price 100.0
  f.price 123.0
  f.quantity 1
  f.status true
  f.association :category
  f.association :manufacturer
end