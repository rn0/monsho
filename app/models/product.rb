class Product
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :name, :type => String
  field :net_price, :type => Float
  field :quantity, :type => Integer
  field :status, :type => Boolean

  validates_presence_of :name, :net_price, :quantity, :status
  validates_numericality_of :net_price, :greater_than => 0
end
