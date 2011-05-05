require "rsolr"

namespace :solr do
  desc "Solr Index --trace"
  task :index => :environment do
    solr = RSolr.connect
    Product.all.each do |p|
      puts p.foreign_key
      unless p.category
        cat = []
      else
        cat = p.category.ancestors_and_self.collect(&:name)
      end
      solr.add({
        :id => p.id,
        :name => p.name,
        :foreign_key => p.foreign_key,
        :status => p.status,
        :price => p.price,
        :category => cat,
        :manufacturer => p.manufacturer.try(:name)
      })
    end
    solr.commit :commit_attributes => {}
  end

  task :all => ["import:a"]
end