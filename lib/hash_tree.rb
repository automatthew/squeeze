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

  # Insert the last arg as a value at the end of the "path"
  # specified by the rest of the args.
  # Ex.
  #  h.insert(:a, :b, :c, "This is a retrievable value")
  #  h.insert(:a, :e, :f, "You don't want to read this value")
  #
  # Individual "path" values may be Strings, Symbols, Regexps, Procs,
  # or Matchers.
  def insert(*args)
    ult = args.pop
    penult = args.pop
    stage = self
    args.each do |a|
      stage = stage[a]
    end
    stage[penult] = ult
  end

  def get(*args)
    ult = args.pop
    penult = args.pop
    stage = self
    args.each do |a|
      stage = stage[a]
    end
    if stage[penult].has_key?(ult)
      stage[penult][ult]
    else
      nil
    end
  end

  def accumulate(*args)
    ult = args.pop
    penult = args.pop
    stage = self
    args.each do |a|
      stage = stage[a]
    end
    unless stage[penult].has_key?(ult)
      stage[penult][ult] = nil
    end
    stage[penult][ult] = yield stage[penult][ult]
  end

  def increment(*args)
    accumulate(*args) do |acc|
      (acc||0) + 1
    end
  end

  #a = rh.accumulator([:a, :b, :c], 0) {|acc, v| acc + v }
  #a[1]
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

  # Given an array of args, attempt to retrieve any values that
  # can be matched.
  def retrieve(*args)
    nodes = [self]
    results = []

    while !nodes.empty?
      nxt = []
      arg = args.shift
      nodes.each do |node|
        if node.kind_of?(HashTree)
          next_keys = matches(arg, node.keys)
          nxt += node.values_at(*next_keys)
        else
          results << node
        end
      end
      nodes = nxt
    end

    results
  end

  def filter(*args)
    nodes = [self]
    results = []

    while !nodes.empty?
      nxt = []
      arg = args.shift
      nodes.each do |node|
        if node.kind_of?(HashTree)
          next_keys = matches(arg, node.keys)
          n = node.values_at(*next_keys)
          nxt += n
          if args.empty?
            results += nxt
            if block_given?
              results.each {|r| yield(r) }
            end
            return results
          end
        end
      end
      nodes = nxt
    end

    results
  end

  def sum(*args)
    out = 0
    filter(*args) do |v|
      out += v
    end
    out
  end

  # For a given value (usually one of the args in a #retrieve sequence)
  # and an Array of keys, return an Array of keys that we consider
  # to match the value.
  def matches(val, keys)
    keys.select do |key|
      case val
      when true
        true
      when String, Symbol
        key == val
        #val == key
      when Regexp
        key =~ val
        #val =~ key
      when Proc, Matcher
        val.call(key)
        #key.call(val)
      else
        raise "Unexpected matcher type: #{val.inspect}"
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



#rh = HashTree.new

#rh.insert(:a, :b, :c, 3)
#acc = rh.accumulator([:a, :b, :c], 0) {|o, n| o + n }
#acc[1]
#acc[1]
#acc[3]

#rh.accumulate(:a, :b, :c) { |v| (v || 0) + 1 }
#rh.accumulate(:a, :b, :c) { |v| (v || 0) + 1 }
#rh.accumulate(:a, :b, :c) { |v| (v || 0) + 1 }


#pp rh

#rh.insert(Matcher.new("/smurf"), :get, "application/json", "JSON") 
#rh.insert(Matcher.new("/smurf"), :get, /html/, "HTML") 
#rh.insert(Matcher.new("/smurf"), :get, "text/html", "specifically HTML") 
#rh.insert("/smurf", :get, true, "who cares?") 
#rh.insert("/smurf", :get, "text/html", "nobody cares?") 
#rh.insert("/smurf", :post, "application/json", lambda { raise "unimplemented" }) 

#pp rh

#pp rh.retrieve("/smurf", :get, "application/json")
#pp rh.retrieve("/smurf", :get, "text/html")
#pp rh.retrieve("/nothing", :get, "text/html")



