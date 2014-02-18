describe "A Postexe node" do
  parse "END { 1 }" do
    [:call, nil, :at_exit, [:arglist, [:iter, nil, [:block, [:lit, 1]]]]]
  end
end
