describe "An If node" do
  parse "x a ? b : c ? d : e" do
    [:call, nil, :x, [:arglist,
     [:if,
      [:call, nil, :a, [:arglist]],
      [:call, nil, :b, [:arglist]],
      [:if,
       [:call, nil, :c, [:arglist]],
       [:call, nil, :d, [:arglist]],
       [:call, nil, :e, [:arglist]]]]]]
  end

  parse "x a ? b ? c : d : e" do
    [:call, nil, :x, [:arglist,
     [:if,
      [:call, nil, :a, [:arglist]],
      [:if,
       [:call, nil, :b, [:arglist]],
       [:call, nil, :c, [:arglist]],
       [:call, nil, :d, [:arglist]]],
      [:call, nil, :e, [:arglist]]]]]
  end
end
