require 'xmlsimple'

Puppet::Functions.create_function(:clickhouse_hash_to_xml) do
    dispatch :default_impl do
        param 'Hash', :data
    end

    dispatch :with_options do
        param 'Hash', :data
        param 'Hash', :options
    end


  def default_impl(data)
    XmlSimple.xml_out(data)
  end

  def with_options(data, options)
    XmlSimple.xml_out(data, options)
  end

    def convert_hash(config)
        XmlSimple.xml_out(config, {"AttrPrefix" => true, 'RootName' => 'yandex'})
    end
end
