class ProductDescription
  include Mongoid::Document

  field :name, :type => String
  field :value
  field :type, :type => String
  field :slug, :type => String

  embedded_in :product
  # TODO: value
  # This is due to the way Object#blank? handles boolean values: false.blank? # => true.
  validates_presence_of :name, :type
  validates_inclusion_of :type, in: ['varchar', 'float', 'int', 'bit']

  before_save :create_slug

  def create_slug
    self.slug = name.to_slug.normalize.to_s
  end
end

