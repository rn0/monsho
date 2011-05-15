namespace :calculate do
  task :category_stats => :environment do
    CategoryStat.calculate
  end

  task :category_facets => :environment do
    CategoryFacet.calculate
  end
end