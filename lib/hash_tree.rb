require "pp"

# A Hash subclass with a default proc as the default_proc,
# so that any time you access a key that doesn't exist, a
# new HashTree is created and set as the value of that key.
# This is very turtle-all-the-way-downy.
#
# A benefit of this is that you can do wicked things like this:
#
#   ht = HashTree.new
#   ht[:do][:re][:mi][:fa] = 42
#
# But the easier way to do that is:
#
#   ht.insert(:do, :re, :mi, :fa, 42)
#
class HashTree < Hash

  # Override the constructor to provide a default_proc
  # NOTE: there's a better way to do this in 1.9.2, it seems.
  # See Hash#default_proc=
  def self.new
    hash = Hash.new { |h,k| h[k] = HashTree.new }
    super.replace(hash)
  end

  # Follow or create the path specified by the signature and assign
  # the value as the terminus.
  # Insert the last arg as a value at the end of the "path"
  # specified by the rest of the args.
  # Ex.
  #  h.insert(:a, :b, :c, "This is a retrievable value")
  #  h.insert(:a, :e, :f, "You don't want to read this value")
  #
  # Individual "path" values may be Strings, Symbols, Regexps, Procs,
  # or Matchers.
  def insert(sig, val)
    raise ArgumentError if sig.empty?
    create_path(sig) do |hash, key|
      hash[key] = val
    end
  end

  def accumulate(sig)
    create_path(sig) do |hash, key|
      unless hash.has_key?(key)
        hash[key] = nil
      end
      hash[key] = yield hash[key]
    end
  end

  def increment(sig, val=1)
    val = yield if block_given?
    create_path(sig) do |hash, key|
      if hash.has_key?(key)
        hash[key] = hash[key] + val
      else
        hash[key] = val
      end
    end
  end

  # Follow the path specified, creating new nodes where necessary.
  # Returns the value at the end of the path. If a block is supplied,
  # it will be called with the last node and the last key as parameters,
  # analogous to Hash.new's default proc. This is necessary to allow
  # setting a value at the end of the path.  See the implementation of #insert.
  def create_path(sig)
    final_key = sig.pop
    hash = self
    sig.each do |a|
      hash = hash[a]
    end
    yield(hash, final_key) if block_given?
    hash[final_key]
  end

  # Attempt to retrieve the value at the end of the path specified,
  # without creating new nodes.  Returns nil on failure.
  # TODO: consider whether splatting the signature is wise.
  def find(*sig)
    stage = self
    sig.each do |a|
      if stage.has_key?(a)
        stage = stage[a]
      else
        return nil
      end
    end
    stage
  end

  # Usage:
  # a = rh.accumulator([:a, :b, :c], 0) {|acc, v| acc + v }
  # a[1]
  def accumulator(args, base, &block)
    ult = args.pop
    penult = args.pop
    stage = self
    args.each do |a|
      stage = stage[a]
    end
    stage = stage[penult]
    unless stage.has_key?(ult)
      stage[ult] = base
    end

    lambda do |newval|
      stage[ult] = block.call(stage[ult], newval)
    end
  end

  def sum(*args)
    out = 0
    filter(*args) do |v|
      out += v
    end
    out
  end

  def filter(*sig)
    results = []
    traverse(*sig) do |node|
      results << node
      yield(node) if block_given?
    end
    results
  end

  def traverse(*sig)
    current_nodes = [self]

    while !current_nodes.empty?

      next_nodes = []
      current_nodes.each do |node|
        if sig.empty?
          yield(node)
        elsif node.kind_of?(HashTree)
          next_keys = match_keys(sig.first, node.keys)
          next_nodes += node.values_at(*next_keys)
        end
      end
      sig.shift
      current_nodes = next_nodes
    end
  end

  def retrieve(*sig)
    results = []
    traverse(*sig) do |node|
      results << node unless node.kind_of?(HashTree)
    end
    results
  end

  # Given an array of args, attempt to retrieve any values that
  # can be matched.
  #def retrieve(*args)
    #current_nodes, results = [self], []

    #while !current_nodes.empty?

      #next_nodes = []
      #current_nodes.each do |node|
        #if node.kind_of?(HashTree)
          #next_keys = match_keys(args.first, node.keys)
          #next_nodes += node.values_at(*next_keys)
        #elsif args.empty?
          #results << node
        #end
      #end
      #args.shift
      #current_nodes = next_nodes
    #end

    #results
  #end

  # For a given value (usually one of the args in a #retrieve sequence)
  # and an Array of keys, return an Array of keys that we consider
  # to match the value.
  def match_keys(val, keys)
    keys.select do |key|
      case val
      when true
        true
      when String, Symbol
        key == val
      when Regexp
        key =~ val
      when Proc, Matcher
        val.call(key)
      when nil
        false
      else
        raise ArgumentError, "Unexpected matcher type: #{val.inspect}"
      end
    end
  end

end


# Matchers are initialized with a pattern, to be used for
# retrieval in a HashTree.  What makes Matcher special,
# really the only reason it exists, is that it overrides #eql?
# and #hash so that Hashes will treat two Matchers as the same
# object if their patterns are the same.  This prevents
# redundancy when a HashTree creates its internal tree.
class Matcher
  attr_reader :pattern
  def initialize(pattern)
    @pattern = pattern || true
  end

  def call(val)
    @pattern == val || @pattern == true
  end

  def eql?(other)
    other.kind_of?(self.class) && other.pattern == @pattern
  end

  def hash
    @pattern.hash
  end
end




