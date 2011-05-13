require 'Zlib'
require 'rsolr'
#module Import

  class ImportA
    attr_accessor :file

    TYPE_MAP = {
      'varchar' => '_s',
      'float' => '_f',
      'int' => '_i',
      'bit' => '_b'
    }

    def initialize(file)
      puts "Using: #{file}"
      @file = file
      @solr = RSolr.connect
      @doc_cache = []
    end

    def import
      start = Time.now

      categories = {}
      categories_path = {}
      category_name = {}
      manufacturers = {}
      manufacturer_name = {}

      products_count = 0

      reader = Nokogiri::XML::Reader.from_io(File.new(@file))
      reader.each do |node|
        next unless node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT
        
        if node.name == "GrupaGlowna"
          main_category_name = Category.find_or_create_by(:name => node.attribute("nazwa"), :parent_id => nil)

          next if node.inner_xml.empty?

          sub_reader = Nokogiri::XML::Reader(node.inner_xml)
          sub_reader.each do |sub_node|
            next unless sub_node.name == "PodGrupa"

            sub_cat = Category.find_or_initialize_by(:name => sub_node.attribute("nazwa"), :parent_id => main_category_name.id)
            sub_cat.parent = main_category_name
            sub_cat.save

            categories_path[sub_node.attribute("id")] = sub_cat.ancestors_and_self.collect(&:id)
            category_name[sub_node.attribute("id")] = sub_cat.ancestors_and_self.collect(&:name)
            categories[sub_node.attribute("id")] = sub_cat.id
          end
        elsif node.name == "producent"
          name = node.attribute("nazwa")
          id = node.attribute("id")

          if id == "BEZ" # HACK!
            name = "Bez nazwy"
          end

          m = Manufacturer.find_or_create_by(:name => name)

          manufacturer_name[id] = name
          manufacturers[id] = m.id
          #puts "#{manufacturer_id} -> #{manufacturer_name}"
        elsif node.name == "produkt"
          foreign_key = node.attribute("id")
          warehouse = 1
          category = categories[node.attribute("grupa")]

          p = Product.where(:foreign_key => foreign_key).first
          p ||= Product.new

          p.name            = node.attribute("nazwa")
          p.foreign_key     = foreign_key
          p.net_price       = node.attribute("cena_netto")
          p.price           = p.net_price + (p.net_price * (node.attribute("vat").to_f / 100))
          #p.warehouse_id    = warehouse
          p.quantity        = node.attribute("dostepny").to_i
          p.status          = (p.quantity > 0)
          p.manufacturer_id = manufacturers[node.attribute("producent")]
          p.manufacturer_name = manufacturer_name[node.attribute("producent")]
          p.category_id     = category unless category.nil?
          p.categories      = categories_path[node.attribute("grupa")]
          p.category_name   = category_name[node.attribute("grupa")]

          unless node.inner_xml.empty?
            params = {}

            xml = "<dummy>#{node.inner_xml}</dummy>"
            crc32 = Zlib.crc32(xml)

            unless p.description_crc == crc32 && 1 == 2
              p.description_crc = crc32

              sub_reader = Nokogiri::XML::Reader(xml)
              sub_reader.each do |sub_node|
                next unless sub_node.name == "parametr"

                value  = sub_node.attribute("opis")
                name = sub_node.attribute("nazwa")
                name = "Opis" if name.empty?
                type = sub_node.attribute("typ")
                #name = name.to_sym
                if type == "float"
                  value.tr!(',', '.')
                  value.tr!(' ', '')
                  value = value.to_f
                  value = value.to_s
                elsif type == "int"
                  value = value.to_i
                #else if type == "bit"
                #  value = value.to_b
                end

                new_item = { name => {
                  :name => name,
                  :value => value,
                  :type => type,
                } }

                params.merge!(new_item) do |name, v1, v2|
                  {
                    :name => name,
                    :value => "#{v1[:value]} #{v2[:value]}",
                    :type => "varchar",
                  }
                end
              end

              p.description = params.reduce([]) do |acc, item|
                acc.push(item[1])
              end
            end
          end

          if p.save
            facets = p.description.reduce({}) do |acc, item|
              t = TYPE_MAP[item[:type]]
              if t && item[:slug] && item[:value]
                acc["f-#{item[:slug]}#{t}"] = item[:value]
              end
              acc
            end

            @doc_cache.push({
              :id => p.id,
              :name => p.name,
              :foreign_key => p.foreign_key,
              :status => p.status,
              :price => p.price,
              :category => p.category_name,
              :manufacturer => p.manufacturer_name
            }.merge!(facets))


            products_count += 1
          else
            puts "#{foreign_key} = #{p.errors.to_a.join('; ')}"
          end

          if products_count % 100 == 0
            @solr.add(@doc_cache)
            @doc_cache.clear
          end

          puts "* #{products_count} in #{Time.now - start} seconds" if products_count % 1000 == 0
        end
      end

      puts "Loaded #{categories.count} categories"
      puts "Loaded #{manufacturers.count} manufacturers"

      puts "Imported #{products_count} products in #{Time.now - start} seconds"

      @solr.add(@doc_cache)
      @doc_cache.clear
      @solr.commit :commit_attributes => {}
    end

  end

#end