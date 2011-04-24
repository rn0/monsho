class Product
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :name, :type => String
  field :net_price, :type => Float
  field :price, :type => Float
  field :quantity, :type => Integer
  field :status, :type => Boolean
  field :foreign_key, :type => String
  field :description, :type => Array
  field :description_crc, :type => Integer

  validates_presence_of :name, :net_price, :quantity, :category_id
  validates_numericality_of :net_price, :greater_than => 0
  validates_inclusion_of :status, :in => [true, false]

  belongs_to :category

  paginates_per 20
end
