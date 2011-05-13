class ProductDescription
  include Mongoid::Document

  field :name, :type => String
  field :value
  field :type, :type => String
  field :slug, :type => String

  embedded_in :product

  validates_presence_of :name, :value, :type
  validates_inclusion_of :type, in: ['varchar', 'float', 'int', 'bit']

  before_save :create_slug

  def create_slug
    self.slug = name.to_slug.normalize.to_s
  end
end

