require "squeeze/traversable"

# A Hash subclass with a default proc that creates another HashTree
# on attempts to access missing keys.
class HashTree < Hash
  include Squeeze::Traversable

  # Override the constructor to provide a default_proc
  # NOTE: there's a better way to do this in 1.9.2, it seems.
  # See Hash#default_proc=
  def self.new()
    hash = Hash.new { |h,k| h[k] = HashTree.new }
    super.replace(hash)
  end

  def self.[](hash)
    ht = self.new
    ht << hash
    ht
  end

  def _dump(depth)
    h = Hash[self]
    h.delete_if {|k,v| v.is_a? Proc }
    Marshal.dump(h)
  end

  def self._load(*args)
    h = Marshal.load(*args)
    ht = self.new
    ht.replace(h)
    ht
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

  def +(other)
    out = HashTree.new
    _plus(other, out)
    out
  end

  def _plus(ht2, out)
    self.each do |k1,v1|
      v1 = v1.respond_to?(:dup) ? v1 : v1.dup
      if ht2.has_key?(k1)
        v2 = ht2[k1]
        if v1.respond_to?(:_plus)
          out[k1] = v1
          v1._plus(v2, out[k1])
        elsif v2.respond_to?(:_plus)
          raise ArgumentError,
            "Can't merge leaf with non-leaf:\n#{v1.inspect}\n#{v2.inspect}"
        else
          if v2.is_a?(Numeric) && v1.is_a?(Numeric)
            out[k1] = v1 + v2
          else
            out[k1] = [v1, ht2[k1]]
          end
        end
      else
        # should anything happen here?
      end
    end
    ht2.each do |k,v|
      if self.has_key?(k)
        # should anything happen here?
      else
        v = v.respond_to?(:dup) ? v : v.dup
        out[k] = v
      end
    end
  end

  def <<(other)
    other.each do |k,v1|
      if self.has_key?(k)
        v2 = self[k]
        if v1.respond_to?(:has_key?) && v2.respond_to?(:has_key?)
          v2 << v1
        elsif v1.is_a?(Numeric) && v2.is_a?(Numeric)
          self[k] = v1 + v2
        else
          raise ArgumentError,
            "Can't merge leaf with non-leaf:\n#{v1.inspect}\n#{v2.inspect}"
        end
      else
        if v1.respond_to?(:has_key?)
          self[k] << v1
        else
          self[k] = v1
        end
      end
    end
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




