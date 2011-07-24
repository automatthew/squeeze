require "squeeze/traversable"

# A Hash subclass with a default proc that creates another HashTree
# on attempts to access missing keys.
class HashTree < Hash
  include Squeeze::Traversable

  # Override the constructor to provide a default_proc
  # NOTE: there's a better way to do this in 1.9.2, it seems.
  # See Hash#default_proc=
  def self.new
    hash = Hash.new { |h,k| h[k] = HashTree.new }
    super.replace(hash)
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

  def children(matcher=true)
    next_keys = self.keys.select do |key|
      match?(matcher, key)
    end
    self.values_at(*next_keys)
  end

  def match?(val, key)
    case val
    when true
      true
    when String, Symbol
      key == val
    when Regexp
      key =~ val
    when Proc
      val.call(key)
    when nil
      false
    else
      raise ArgumentError, "Unexpected matcher type: #{val.inspect}"
    end
  end

end




