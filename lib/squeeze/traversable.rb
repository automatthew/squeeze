class Squeeze
  # Tree classes including this module must supply these methods:
  #
  # * #create_path(path_signature)
  # * #find(path_signature)
  # * #children(node_matcher)
  module Traversable

    # Follow or create the path specified by the signature and assign
    # the value as a terminating leaf node.
    #  
    #  h.set([:a, :b, :c], "This is a retrievable value")
    #
    def set(sig, val)
      raise ArgumentError if sig.empty?
      create_path(sig) do |node, key|
        node[key] = val
      end
    end

    def reduce(sig, base=0)
      create_path(sig) do |node, key|
        node[key] = base unless node.has_key?(key)
        node[key] = yield node[key]
      end
    end

    def increment(sig, val=1)
      val = yield if block_given?
      create_path(sig) do |node, key|
        if node.has_key?(key)
          node[key] = node[key] + val
        else
          node[key] = val
        end
      end
    end

     # Usage:
    # a = ht.reducer([:a, :b, :c], 0) {|acc, v| acc + v }
    # a[1]
    def reducer(sig, base, &block)
      p = nil
      create_path(sig) do |node, key|
        unless node.has_key?(key)
          node[key] = base
        end
        p = lambda do |newval|
          node[key] = block.call(node[key], newval)
        end
      end
      p
    end

    def sum(*args)
      out = 0
      retrieve(*args) { |v| out += v }
      out
    end

    def count(*args)
      args = args + [:_count]
      sum(*args)
    end

    def unique(*args)
      out = 0
      filter(*args) { |v| out += v.size }
      out
    end

    # like retrieve, but will return any kind of node
    def filter(*sig)
      results = []
      search(sig) do |node|
        results << node
        yield(node) if block_given?
      end
      results
    end

    # Given a signature array, attempt to retrieve matching leaf values.
    def retrieve(*sig)
      results = []
      search(sig) do |node|
        results << node unless node.respond_to?(:children)
        yield(node) if block_given?
      end
      results
    end

    # Generic tree search method
    def search(sig)
      current_nodes = [self]

      while !current_nodes.empty?
        next_nodes = []
        matcher = sig.shift
        if matcher
          current_nodes.each do |node|
            if node.respond_to?(:children)
              next_nodes += node.children(matcher)
            end
          end
        else
          current_nodes.each {|n| yield(n) }
        end
        current_nodes = next_nodes
      end
    end

    def traverse
      current_nodes = [self]
      while !current_nodes.empty?
        next_nodes = []
        current_nodes.each do |node|
          if node.respond_to?(:children)
            next_nodes += node.children(true)
            yield(node)
          end
        end

        current_nodes = next_nodes
      end
    end

  end
end
