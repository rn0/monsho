#require 'Lib/Import/Action.rb'

namespace :import do
  desc "Import A-XML\nUsage: rake import:a file=action.xml --trace"
  task :a => :environment do
    # TODO: handling arguments

    require File.expand_path('lib/import-a.rb')
    action = ImportA.new(ENV['file'])
    action._import;
  end

  task :all => ["import:a"]
end