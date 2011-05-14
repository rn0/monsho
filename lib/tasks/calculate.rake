namespace :calculate do
  task :category_stats => :environment do
    CategoryStat.calculate
  end
end