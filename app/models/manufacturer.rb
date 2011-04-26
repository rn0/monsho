class Manufacturer
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String

  has_many :products
end
