require 'xmlsimple'

Puppet::Functions.create_function(:clickhouse_hasherizer) do
    dispatch :hasherizer do
        param 'Hash', :config
    end

    def hasherizer(config)
        convert_hash(config)
    end

    def convert_hash(hash, path = "")
      hash.each_with_object({}) do |(k, v), ret|
        key = path + k

        if v.is_a? Hash
          ret.merge! convert_hash(v, key + ".")
        else
          ret[key] = v
        end
      end
    end

end
