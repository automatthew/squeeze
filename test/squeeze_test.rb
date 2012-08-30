require "test/setup"
require "squeeze"


context("Squeeze") do
  helper(:records) do
    [
      {:beastie => "smurf", :color => "blue", :size => "small"},
      {:beastie => "gnome", :color => "gray", :size => "small"},
      {:beastie => "cave troll", :color => "charcoal", :size => "large"},
      {:beastie => "bridge troll", :color => "gray", :size => "medium"},
      {:beastie => "brownie", :color => "brown", :size => "small"},
      {:beastie => "kobold", :color => "brown", :size => "small"},
      {:beastie => "elf", :color => "gold", :size => "medium"},
      {:beastie => "pixie", :color => "gold", :size => "tiny"},
      {:beastie => "jotunn", :color => "white", :size => "large"},
      {:beastie => "yeti", :color => "white", :size => "large"},
    ]
  end

  setup do
    s = Squeeze.new(
      :fields => {:size => :color}
    )
    s.reduce(records)
    s
  end

  # FAILING: apparently I changed the behavior without changing the test.
  asserts("frequency count") do
    pp topic.output
    topic == {
      :size => {
        "small" => 4,
        "large" => 1,
        "medium" => 2,
        "giant" => 1,
        "tiny" => 1
      },
    }
  end

end


