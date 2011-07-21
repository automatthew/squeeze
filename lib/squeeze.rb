require "hash_tree"

class Squeeze

  attr_reader :output

  def initialize(options)
    @fields = options[:fields]
    @derived = options[:derived] || {}
    @output = HashTree.new
  end

  # Takes an array of hashes, keyed with Symbols
  def reduce(records)
    records.each do |record|
      process(@output, record, @fields)
    end
  end

  def process(output, record, fields, sig=[])
    fields.each do |field, subfields|
      key = resolve(field, record)
      case subfields
      when true
        output.increment(*(sig + [field, key]))
      when Symbol
        output.increment(*(sig + [field, key, :_count]))
        value = resolve(subfields, record)
        output.increment(*(sig + [field, key, subfields, value]))
      when Array
        subfields.each do |subfield|
          process(output, record, {field => subfield}, sig )
        end
      when Hash
        process(output, record, subfields, sig + [field, key])
      end
 
    end
  end

  def resolve(name, record)
    if p = @derived[name]
      p.call(record)
    elsif record.respond_to?(name)
      record.send(name)
    else
      record[name] || "unknown"
    end
  end

end
