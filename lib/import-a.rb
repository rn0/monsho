require 'rubygems'
require 'Zlib'
require 'tire'
#module Import

  class ImportA
    TYPE_MAP = {
      'varchar' => '_s',
      'float' => '_f',
      'int' => '_i',
      'bit' => '_b'
    }
    
    TRUE_VALUES = [true, 1, '1', 't', 'T', 'true', 'TRUE', 'True', 'Tak'].to_set
    INDEX_NAME = 'monsho-catalog'

    def initialize(file)
      puts "Using: #{file}"
      @start = Time.now
      @reader = Nokogiri::XML::Reader.from_io(File.new(file))

      @categories = {}
      @categories_path = {}
      @category_name = {}
      @manufacturers = {}
      @manufacturer_name = {}
      @doc_cache = []

      Tire.index INDEX_NAME do
        create({
          :settings => {
            :number_of_shards   => 1,
            :number_of_replicas => 0
          },
          :mappings => {
            :product => {
              :dynamic_templates => [
                {
                  :facets_not_analyzed => {
                    :path_match => 'facets.*',
                    :mapping => {
                      :index => 'not_analyzed'
                    }
                  }
                }
              ],
              :properties => {
                :id             => { :type => 'string', :index => 'no' },
                :category       => { :type => 'string', :index => 'not_analyzed' },
                :manufacturer   => { :type => 'string', :index => 'not_analyzed' },
                :facets         => {
                  :properties   => {
                    :zasilanie                => { :type => 'string' },
                    :wydajnosc                => { :type => 'string' },
                    :pojemnosc                => { :type => 'string' },
                    :'wbudowana-pamiec'       => { :type => 'string' },
                    :bateria                  => { :type => 'string' },
                    :waga                     => { :type => 'string' },
                    :'rozdzielczosc-wydruku'  => { :type => 'string' },
                    :'interfejs-fdd'          => { :type => 'string' },
                    :'napiecie-zasilania'     => { :type => 'string' },
                    :'ciezar'                 => { :type => 'string' },
                    :'napiecie-wejsciowe'     => { :type => 'string' },
                    :'zdolnosc-zamrazania-na-dobe' => { :type => 'string' },
                    :'poziom-halasu'          => { :type => 'string' },
                  }
                }
              }
            }
          }
        })
      end
    end

    def index_properties refresh_interval, merge_factor
      RestClient.put "#{es_base_path}/_settings ", %<{
        "index" : {
            "refresh_interval" : "#{refresh_interval}",
            "merge.policy.merge_factor" : #{merge_factor}
        }
      }>
    end

    def optimize_index
      RestClient.get "#{es_base_path}/_optimize?max_num_segments=5 "
    end

    def es_base_path
      @path ||= [Tire::Configuration.url, INDEX_NAME].join '/'
    end

    def _import
      products_count = 0

      index_properties '-1', 30

      @reader.each do |node|
        next unless node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT

        if node.name == "GrupaGlowna"
          main_category_name = Category.find_or_create_by(:name => node.attribute("nazwa"), :parent_id => nil)

          next if node.inner_xml.empty?

          process_subcategory_node(main_category_name, node)
        elsif node.name == "producent"
          process_manufacturer_node(node)
        elsif node.name == "produkt"

          if process_product_node(node)
            products_count += 1
          end

          if products_count % 100 == 0
            store @doc_cache
          end

          puts "* #{products_count} in #{Time.now - @start} seconds" if products_count % 1000 == 0
        end
      end

      store @doc_cache

      index_properties '1s', 10
      optimize_index

      puts "Loaded #{@categories.count} categories"
      puts "Loaded #{@manufacturers.count} manufacturers"
      puts "Imported #{products_count} products in #{Time.now - @start} seconds"
    end

    private

    def process_manufacturer_node(node)
      name = node.attribute("nazwa")
      id = node.attribute("id")

      if id == "BEZ" # HACK!
        name = "Bez nazwy"
      end

      m = Manufacturer.find_or_create_by(:name => name)

      @manufacturer_name[id] = name
      @manufacturers[id] = m.id
    end

    def process_subcategory_node(main_category_name, node)
      sub_reader = Nokogiri::XML::Reader(node.inner_xml)
      sub_reader.each do |sub_node|
        next unless sub_node.name == "PodGrupa"

        sub_cat = Category.find_or_initialize_by(:name => sub_node.attribute("nazwa"), :parent_id => main_category_name.id)
        sub_cat.parent = main_category_name
        sub_cat.save

        @categories_path[sub_node.attribute("id")] = sub_cat.ancestors_and_self.collect(&:id)
        @category_name[sub_node.attribute("id")] = sub_cat.ancestors_and_self.collect(&:name)
        @categories[sub_node.attribute("id")] = sub_cat.id
      end
    end


    def process_product_node node
      foreign_key = node.attribute("id")
      #warehouse = 1
      category = @categories[node.attribute("grupa")]

      p = Product.where(:foreign_key => foreign_key).first
      p ||= Product.new

      p.name            = node.attribute("nazwa")
      p.foreign_key     = foreign_key
      p.net_price       = node.attribute("cena_netto").to_f.round(2)
      price = p.net_price + (p.net_price * (node.attribute("vat").to_f / 100))
      p.price           = price.round(2)
      #p.warehouse_id    = warehouse
      p.quantity        = node.attribute("dostepny").to_i
      p.status          = (p.quantity > 0)
      p.manufacturer_id = @manufacturers[node.attribute("producent")]
      p.manufacturer_name = @manufacturer_name[node.attribute("producent")]
      p.category_id     = category unless category.nil?
      p.categories      = @categories_path[node.attribute("grupa")]
      p.category_name   = @category_name[node.attribute("grupa")]

      crc32, description = process_product_description node, p.description_crc
      p.description = description

      if p.save
        facets = p.description.reduce({}) do |acc, item|
          if item[:slug] && !item[:value].nil?
            acc[item[:slug]] = item[:value]
          end
          acc
        end

        @doc_cache.push({
          :type => 'product',
          :id => p.id,
          :name => p.name,
          :foreign_key => p.foreign_key,
          :status => p.status,
          :price => p.price,
          :category => p.category_name,
          :manufacturer => p.manufacturer_name,
          :facets => facets
        })
      else
        puts "#{foreign_key} = #{p.errors.to_a.join(";\n")}"
      end
    end

    def process_description_item node
      value  = node.attribute("opis")
      name = node.attribute("nazwa")
      name = 'Opis' if name.empty?
      type = node.attribute("typ")

      if value == 'Tak' || value == 'Nie' || value == 'True' || value == 'False'
        type = 'bit'
      end

      if type == 'float'
        value.tr!(',', '.')
        value.tr!(' ', '')
        value = value.to_f
      elsif type == 'int'
        value = value.to_i
      elsif type == 'bit'
        value = value_to_boolean value
      end

      { name => {
        :name => name,
        :value => value,
        :type => type,
      } }
    end

    def process_product_description node, description_crc
      #facets = []
      description = []
      crc32 = nil

      unless node.inner_xml.empty?
        xml = "<dummy>#{node.inner_xml}</dummy>"
        crc32 = Zlib.crc32(xml)
        params = {}

        unless description_crc == crc32 && 1 == 2
          sub_reader = Nokogiri::XML::Reader(xml)
          sub_reader.each do |sub_node|
            next unless sub_node.name == "parametr"

            new_item = process_description_item sub_node
            params.merge!(new_item) do |name, v1, v2|
              {
                :name => name,
                :value => "#{v1[:value]} #{v2[:value]}",
                :type => "varchar",
              }
            end
          end
        end

        description = params.reduce([]) do |acc, item|
#          if item[1][:slug] && item[1][:value]
#            facets[item[1][:slug]] = item[1][:value]
#          end
          acc.push(ProductDescription.new(item[1]))
          #acc
        end
      end

      [crc32, description]
    end

    # File activerecord/lib/active_record/connection_adapters/abstract/schema_definitions.rb, line 150
    def value_to_boolean(value)
      if value.is_a?(String) && value.empty?
        nil
      else
        TRUE_VALUES.include?(value)
      end
    end

    def store docs
      Tire.index INDEX_NAME do
        bulk_store docs
      end
      docs.clear
    end
  end

#end