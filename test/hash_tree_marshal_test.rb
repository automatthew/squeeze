require "test/setup"
require "squeeze/hash_tree"

#topic = HashTree.new
#topic.set([:foo, :bar, :baz], :bat)
#topic.set([:foo, :moo, :soo], :what)

#d = Marshal.dump(topic)
#nd = Marshal.load(d)
#nd.set([:foo, :moo, :tru], :hi)
#pp nd

t0 = HashTree.new
t0.set([1, 2, 3], 22)
t0 << {1=>{2=>{3=>11}}, :a=>{:g=>{:h=>:i}, :b=>{:c=>:d, :e=>:f}}}

pp t0

pp HashTree[t0]
exit

t1 = HashTree.new
t2 = HashTree.new

t1.set([:a, :b, :c], :d)
t1.set([:a, :b, :e], :f)
t1.set([:a, :g, :h], :i)
t1.set([1, 2, 3], 11)


t2.set([1, 2, 3], 4)
t2.set([1, 5, 6], 7)
t2.set([:a, :j, :k], :l)
t2.set([:a, :b, :x], :y)
t2.set([:a, :b, :c], :y)


t3 = t1 + t2
pp t3


expected = {
  :a => {
    :b => {
      :c => [:d, :y],
      :e => :f,
      :x => :y
    },
    :g => {
      :h => :i
    },
    :j => {
      :k => :l
    }
  },
  1 => {
    5 => {
      6 => 7
    },
    2 => {
      3 => 15
    }
  },

}


pp expected == t3

