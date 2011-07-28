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
      process(record, @fields)
    end
  end

  def process(record, fields, sig=[])
    case fields
    when Hash
      fields.each do |field, subfields|
        process_field(record, field, subfields, sig)
      end
    when Array
      fields.each do |field|
        process_field(record, field, true, sig)
      end
    end
  end

  def process_field(record, field, subfields, sig)
    key = resolve(field, record)
    case subfields
    when true
      output.increment(sig + [field, key])
    when Symbol
      output.increment(sig + [field, key, :_count])
      value = resolve(subfields, record)
      output.increment(sig + [field, key, subfields, value])
    when Array
      subfields.each do |subfield|
        process(record, {field => subfield}, sig )
      end
    when Hash
      process(record, subfields, sig + [field, key])
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
