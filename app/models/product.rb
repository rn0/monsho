class Product
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :name, :type => String
  field :net_price, :type => Float
  field :price, :type => Float
  field :quantity, :type => Integer
  field :status, :type => Boolean
  index :status
  field :foreign_key, :type => String
  field :description_crc, :type => Integer
  field :categories, :type => Array
  field :category_name, :type => Array
  field :manufacturer_name, :type => String

  validates_presence_of :name, :net_price, :quantity, :category_id, :manufacturer_id
  validates_numericality_of :net_price, :greater_than => 0
  validates_numericality_of :price, :greater_than => 0
  validates_inclusion_of :status, :in => [true, false]

  belongs_to :category
  belongs_to :manufacturer
  embeds_many :description, class_name: 'ProductDescription'

  scope :active, where("status" => true)
  scope :inactive, where("status" => false)

  after_validation :validate_description
  def validate_description
    unless self.errors.empty?
      self.description.each do |d|
        d.errors.each { |attr, msg| self.errors.add(attr, msg) }
      end
    end
  end
end
