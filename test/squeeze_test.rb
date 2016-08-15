require_relative "setup"
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

  asserts("frequency count") do
    {
      :size => {
        "small" => {
          :_count =>4,
          :color => {"blue" => 1, "gray" => 1, "brown" => 2}
        },
        "large" => {
          :_count =>3,
          :color => {"charcoal" => 1, "white" => 2}
        },
        "medium" => {
          :_count => 2,
          :color => {"gray" => 1, "gold" => 1}
        },
        "tiny" => {
          :_count => 1,
          :color => {"gold" => 1}
        }
      }
    }
  end

end


