require "test/setup"
require "hash_tree"


context("HashTree") do
  setup do
    HashTree.new
  end

  context("#[]=") do
    hookup { topic[:normal] = "normal" }
    should("assign the value in the usual way") { topic[:normal] == "normal" }
  end

  context("#[]") do
    hookup do
      topic[:existing] = 1
    end
    context("where key exists") do
      should("return the expected value") { topic[:existing] == 1 }
    end
    context("where key does not exist") do
      asserts("return value") { topic[:nonexistent] }.kind_of(HashTree)
    end
  end

  context("#set") do
    hookup { topic.set([:foo, :bar, :baz], :bat) }
    should("store the last argument") { topic[:foo][:bar][:baz] == :bat }
    context("with an empty signature") do
      should { topic.set([], :smurf) }.raises(ArgumentError)
    end
  end

  context("#find") do
    hookup do
      topic[:a][:b][:c] = :d
      topic[:a][:b][:e] = :f
      topic[1][2][3] = 4
    end

    should("return single object when path exists") { topic.find(:a, :b, :e) == :f }
    should("return nil when path not found") { topic.find(:a, :b, :f) == nil }
    should("work on subtree paths") { topic.find(:a, :b).class == HashTree }
  end

  context("#traverse") do
    context("with no arguments") do
      setup do
        topic[:a][:b][:c] = :d
        topic[:a][:b][:e] = :f
        topic[1][2][3] = 4 
        out = []
        topic.traverse do |n|
          out << n
        end
        #pp out
        out
      end
      should("visit every node once") do
        topic.size == 5
        #topic == [[1, :a], [2], [:b], [3], [:e, :c], 4, :f, :d]
      end
    end
  end

  context("#match?") do
    context("true") do
      asserts("always matches") do
        [1, :one, "one", false, nil, true].all? do |k|
          topic.match?(true, k)
        end
      end
    end

    context("regex") do
      setup do
        [:foo, "food", nil, true, false].select do |k|
          topic.match?(/foo/, k)
        end
      end
      asserts("matches where the regex would") do
        topic == ["food"]
      end
    end

    context("proc") do
      helper :integer_test do
        lambda { |key| key.is_a? Integer }
      end
      setup do
        [1, :one, "one"].select do |k|
          topic.match?(integer_test, k)
        end
      end
      asserts("matches if proc return value is true") do
        topic == [1]
      end
    end

    context("symbol") do
      asserts("matches exact symbol") do
        out = ["one", :one, :onerous, 1].select do |k|
          topic.match?(:one, k)
        end
        out == [:one]
      end
    end

    context("string") do
      asserts("matches exact string") do
        out = ["one", :one, "onerous", 1].select do |k|
          topic.match?("one", k)
        end
        out == ["one"]
      end
    end

    context("unsupported value") do
      should do
        topic.match?(Object.new, [1, 2])
      end.raises(ArgumentError, "Unexpected matcher type")
    end
  end

  context("#reduce") do
    context("with no base argument") do
      hookup do
        topic.reduce([:a, :b, :c]) {|v| v + 2 }
        topic.reduce([:a, :b, :c]) {|v| v + 2 }
      end
      should("uses a base value of 0") do
        topic.find(:a, :b, :c) == 4
      end
    end
    context("with a base argument") do
      hookup do
        topic.reduce([:a, :b, :c], []) {|v| v << 2 }
        topic.reduce([:a, :b, :c], []) {|v| v << 3 }
      end
      should("use that base") do
        topic.find(:a, :b, :c) == [2, 3]
      end
    end
  end

  context("#increment") do
    context("with no value specified") do
      hookup do
        topic.increment([:a, :b, :c])
        topic.increment([:a, :b, :c])
        topic.increment([:a, :b, :c])
      end
      should("increment the path terminus by 1") do
        topic.find(:a, :b, :c) == 3
      end
    end
    context("with a value") do
      hookup do
        topic.increment([:a, :b, :c], 1)
        topic.increment([:a, :b, :c], 2)
        topic.increment([:a, :b, :c], 3)
      end
      should("increment the path terminus by that value") do
        topic.find(:a, :b, :c) == 6
      end
    end
    context("with a block") do
      hookup do
        topic.increment([:a, :b, :c]) { 17 }
        topic.increment([:a, :b, :c]) { 9 }
      end
      should("increment by the value returned by the block") do
        topic.find(:a, :b, :c) == 26
      end
    end
    context("return value") do
      setup do
        topic.increment([:a, :b, :c])
        topic.increment([:a, :b, :c])
        topic.increment([:a, :b, :c])
      end
      should("be the the accumulation") { topic == 3 }
    end
  end

  context("#reducer") do
    context("returns an reducer") do
      context("which acts on the HashTree") do
        hookup do
          a = topic.reducer([:a, :b, :c], 0) {|acc, v| acc + v }
          a[1]
          a[3]
        end
        should "accumulate a result" do
          topic.find(:a, :b, :c) == 4
        end
      end

      context("which when called") do
        setup do
          a = topic.reducer([:a, :b, :c], 0) {|acc, v| acc + v }
          a[1]
          a[1]
          a[3]
          a
        end
        should "return the accumulation" do
          topic[1] == 6
        end
      end

    end

  end

  context("#retrieve") do
    hookup do
      topic.set([:a, :b, :c], :d)
      topic.set(%w[little blue thing], :smurf)
      topic.set(%w[little red demon], :imp)
      topic[:a][:b][:e] = :f
      topic[1][2][3] = 4
    end
    should("return empty array when no match") do
      topic.retrieve(:nothing, :here) == []
    end
    should("return result array for exact matches") do
      topic.retrieve(:a, :b, :c) == [:d]
    end
    should("not return anything on partial matches") do
      topic.retrieve(:a, :b) == []
    end
    should("return empty when sig is longer than a match") do
      topic.retrieve(:a, :b, :c, :monkey) == []
    end
    should("use loose matching") do
      topic.retrieve("little", /blue|red/, true) == [:smurf, :imp]
    end
  end

  context("#filter") do
    hookup do
      topic.set(%w[a b c d], :one)
      topic.set(%w[a b c e], :two)
      topic.set(%w[a 1 c 2], :three)
      topic.set(%w[x y z], :four)
    end
    should("return values which match") do
      topic.filter("x", "y", "z") == [:four]
    end
    should("return nodes which match the signature") do
      topic.filter("a", true, "c") == [
        {"d" => :one, "e" => :two},
        {"2" => :three }
      ]
    end
    should("return empty array on no matches") do
      topic.filter(:nothing, :here) == []
    end
  end

end

