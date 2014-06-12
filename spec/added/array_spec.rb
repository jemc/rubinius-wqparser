describe "An Array node" do
  parse "[1, *[2, 3], 4, *[5, 6]]" do
     [:array, [:lit, 1], [:lit, 2], [:lit, 3], [:lit, 4], [:lit, 5], [:lit, 6]]
  end
end
