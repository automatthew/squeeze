class Squeeze

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

end
