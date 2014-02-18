describe "A Hash node" do
  parse "{ 1 => 2, 3 => 4 }" do
    [:hash, [:lit, 1], [:lit, 2], [:lit, 3], [:lit, 4]]
  end

  parse "{ 1 => (2 rescue 3) }" do
    [:hash,
     [:lit, 1],
     [:rescue,
      [:lit, 2],
      [:resbody, [:array, [:const, :StandardError]], [:lit, 3]]]]
  end

  parse "{ 1 => [*1] }" do
    [:hash, [:lit, 1], [:splat, [:lit, 1]]]
  end

  parse <<-ruby do
      a = 1
      { :a => a }
    ruby

    [:block,
      [:lasgn, :a, [:lit, 1]],
      [:hash, [:lit, :a], [:lvar, :a]]]
  end
end
