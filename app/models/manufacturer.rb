class Manufacturer
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String

  has_many :products

  def self.group_by_name
    order_by([:name, :asc]).all.group_by do |manufacturer|
      manufacturer.name[0, 1].upcase
    end
  end
end
