require "hash_tree"

module Squeezable
  def self.included(mod)
    mod.module_eval do
      extend ClassMethods
      include InstanceMethods
    end
  end

  module ClassMethods
    def squeezable(options=nil)
      if options
        @squeeze_spec = options
      else
        @squeeze_spec || superclass.squeezable
      end
    end
  end

  module InstanceMethods
    def squeeze
      meth = self.class.squeezable[:dataset_method]
      squeezer.reduce(self.send(meth))
    end

    def squeezer
      @squeezer ||= Squeeze.new(:fields => self.class.squeezable[:fields])
    end
  end
end

class Squeeze

  attr_reader :output
  attr_accessor :reports, :derived

  def self.fields(spec=nil)
    @fields ||= {}
    spec ? @fields = spec : @fields
  end

  def initialize(options={})
    f = options[:fields] || {}
    @fields = self.class.fields.merge(f)
    @derived = options[:derived] || {}
    @output = HashTree.new
  end

  # Takes an array of hashes, keyed with Symbols
  def reduce(records)
    records.each do |record|
      process(record, @fields)
    end
    @output
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
    return unless key = resolve(field, record)
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
      output.increment(sig + [field, key, :_count])
      process(record, subfields, sig + [field, key])
    end
  end

  def resolve(name, record)
    result = if v = record[name]
      v
    elsif p = @derived[name]
      p.call(record)
    elsif record.respond_to?(name)
      record.send(name)
    else
      :_unknown
    end
  end

end
