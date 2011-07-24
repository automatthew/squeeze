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

  context("#insert") do
    hookup { topic.insert([:foo, :bar, :baz], :bat) }
    should("store the last argument") { topic[:foo][:bar][:baz] == :bat }
    context("with an empty signature") do
      should { topic.insert([], :smurf) }.raises(ArgumentError)
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

  context("#match_keys") do
    context("on true") do
      should("return all keys") do
        topic.match_keys(true, [false, 1, :one, "one"]) == [false, 1, :one, "one"]
      end
    end
    context("on regex") do
      should("return keys that match the regex") do
        topic.match_keys(/bc/, %w[abcd foo]) == %w[abcd]
      end
    end
    context("on proc") do
      helper :integer_test do
        lambda { |key| key.is_a? Integer }
      end
      should("return keys for which proc returns truthy") do
        topic.match_keys(integer_test, [1, :one, "one"]) == [1]
      end
    end
    context("on symbol") do
      should("return keys which are the symbol") do
        topic.match_keys(:monkey, [:dog, :cat, :smurf, :monkey]) == [:monkey]
      end
    end
    context("on string") do
      should("return keys which are the string") do
        topic.match_keys("monkey", ["ape", "monkey"]) == ["monkey"]
      end
    end
    context("on anything else") do
      should do
        topic.match_keys({}, [1, 2])
      end.raises(ArgumentError, "Unexpected matcher type")
    end
  end

  context("#accumulate") do
    hookup do
      topic.accumulate([:a, :b, :c]) {|v| (v||0) + 2 }
      topic.accumulate([:a, :b, :c]) {|v| (v||0) + 2 }
    end
    should("run and accumulate block results on chosen path") do
      topic.find(:a, :b, :c) == 4
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
  end

  context("An accumulator") do
    hookup do
      a = topic.accumulator([:a, :b, :c], 0) {|acc, v| acc + v }
      a[1]
      a[1]
      a[3]
    end
    should "work" do
      topic.find(:a, :b, :c) == 5
    end
  end

  context("#retrieve") do
    hookup do
      topic.insert([:a, :b, :c], :d)
      topic.insert(%w[little blue thing], :smurf)
      topic.insert(%w[little red demon], :imp)
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
      topic.insert(%w[a b c d], :one)
      topic.insert(%w[a b c e], :two)
      topic.insert(%w[a 1 c 2], :three)
      topic.insert(%w[x y z], :four)
    end
    should("return values which match") do
      topic.filter("x", "y", "z") == [:four]
    end
    should("return nodes which match the signature") do
      #topic.filter("a", true, "c") == {
        #"c" => {
          #"d" => :one,
          #"e" => :two,
          #"2" => :three
        #}
      #}
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

