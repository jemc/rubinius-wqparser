describe "A Defn node" do
  parse <<-ruby do
      def m
      end
    ruby

    [:defn, :m, [:args], [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m() end
    ruby

    [:defn, :m, [:args], [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(a) end
    ruby

    [:defn, :m, [:args, :a], [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m((a)) end
    ruby

    [:defn,
     :m,
     [:args, [:masgn, [:array, [:lasgn, :a]]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m((*a, b)) end
    ruby

    [:defn,
     :m,
     [:args, [:masgn, [:array, [:splat, [:lasgn, :a]]], [:lasgn, :b]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(a=1) end
    ruby

    [:defn,
      :m,
      [:args, :a, [:block, [:lasgn, :a, [:lit, 1]]]],
      [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(*) end
    ruby

    [:defn, :m, [:args, :*], [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(*a) end
    ruby

    [:defn, :m, [:args, :"*a"], [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(a:) end
    ruby

    [:defn, :m, [:args, :a, [:block, [:a]]], [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(a: 1) end
    ruby

    [:defn,
     :m,
     [:args, :a, [:block, [:a], [[:lasgn, :a, [:lit, 1]]]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(**) end
    ruby

    [:defn, :m, [:args, :**, [:block, [:**]]], [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(**k) end
    ruby

    [:defn, :m, [:args, :"**k", [:block, [:"**k"]]], [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(&b) end
    ruby

    [:defn, :m, [:args, :"&b"], [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(a, b) end
    ruby

    [:defn, :m, [:args, :a, :b], [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(a, (b, c)) end
    ruby

    [:defn,
     :m,
     [:args, :a, [:masgn, [:array, [:lasgn, :b], [:lasgn, :c]]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m((a), (b)) end
    ruby

    [:defn,
     :m,
     [:args, [:masgn, [:array, [:lasgn, :a]]], [:masgn, [:array, [:lasgn, :b]]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m((*), (*)) end
    ruby

    [:defn,
     :m,
     [:args, [:masgn, [:array, [:splat]]], [:masgn, [:array, [:splat]]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m((*a), (*c)) end
    ruby

    [:defn,
     :m,
     [:args,
      [:masgn, [:array, [:splat, [:lasgn, :a]]]],
      [:masgn, [:array, [:splat, [:lasgn, :c]]]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m((a, b), (c, d)) end
    ruby

    [:defn,
     :m,
     [:args,
      [:masgn, [:array, [:lasgn, :a], [:lasgn, :b]]],
      [:masgn, [:array, [:lasgn, :c], [:lasgn, :d]]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m((a, *b), (*c, d)) end
    ruby

    [:defn,
     :m,
     [:args,
      [:masgn, [:array, [:lasgn, :a], [:splat, [:lasgn, :b]]]],
      [:masgn, [:array, [:splat, [:lasgn, :c]]], [:lasgn, :d]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m((a, b, *c, d), (*e, f, g), (*h)) end
    ruby

    [:defn,
     :m,
     [:args,
      [:masgn,
       [:array, [:lasgn, :a], [:lasgn, :b], [:splat, [:lasgn, :c]]],
       [:lasgn, :d]],
      [:masgn, [:array, [:splat, [:lasgn, :e]]], [:lasgn, :f], [:lasgn, :g]],
      [:masgn, [:array, [:splat, [:lasgn, :h]]]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(a, (b, (c, *d), *e)) end
    ruby

    [:defn,
     :m,
     [:args,
      :a,
      [:masgn,
       [:array,
        [:lasgn, :b],
        [:masgn, [:array, [:lasgn, :c], [:splat, [:lasgn, :d]]]],
        [:splat, [:lasgn, :e]]]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(a, (b, (c, *d, (e, (*f)), g), (h, (i, j)))) end
    ruby

    [:defn,
     :m,
     [:args,
      :a,
      [:masgn,
       [:array,
        [:lasgn, :b],
        [:masgn,
         [:array, [:lasgn, :c], [:splat, [:lasgn, :d]]],
         [:masgn,
          [:array, [:lasgn, :e], [:masgn, [:array, [:splat, [:lasgn, :f]]]]]],
         [:lasgn, :g]],
        [:masgn,
         [:array,
          [:lasgn, :h],
          [:masgn, [:array, [:lasgn, :i], [:lasgn, :j]]]]]]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(a, b=1) end
    ruby

    [:defn,
     :m,
     [:args, :a, :b, [:block, [:lasgn, :b, [:lit, 1]]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(a, *) end
    ruby

    [:defn, :m, [:args, :a, :*], [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(a, *b) end
    ruby

    [:defn, :m, [:args, :a, :"*b"], [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(a, b:) end
    ruby

    [:defn, :m, [:args, :a, :b, [:block, [:b]]], [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(a, b: 1) end
    ruby

    [:defn,
     :m,
     [:args, :a, :b, [:block, [:b], [[:lasgn, :b, [:lit, 1]]]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(a, **) end
    ruby

    [:defn, :m, [:args, :a, :**, [:block, [:**]]], [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(a, **k) end
    ruby

    [:defn,
     :m,
     [:args, :a, :"**k", [:block, [:"**k"]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(a, &b) end
    ruby

    [:defn, :m, [:args, :a, :"&b"], [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(a=1, b) end
    ruby

    [:defn,
     :m,
     [:args, :a, :b, [:block, [:lasgn, :a, [:lit, 1]]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(a=1, *) end
    ruby

    [:defn,
     :m,
     [:args, :a, :*, [:block, [:lasgn, :a, [:lit, 1]]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(a=1, *b) end
    ruby

    [:defn,
     :m,
     [:args, :a, :"*b", [:block, [:lasgn, :a, [:lit, 1]]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(a=1, (b, c)) end
    ruby

    [:defn,
     :m,
     [:args,
      :a,
      [:masgn, [:array, [:lasgn, :b], [:lasgn, :c]]],
      [:block, [:lasgn, :a, [:lit, 1]]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(a=1, (b, (c, *d))) end
    ruby

    [:defn,
     :m,
     [:args,
      :a,
      [:masgn,
       [:array,
        [:lasgn, :b],
        [:masgn, [:array, [:lasgn, :c], [:splat, [:lasgn, :d]]]]]],
      [:block, [:lasgn, :a, [:lit, 1]]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(a=1, (b, (c, *d), *e)) end
    ruby

    [:defn,
     :m,
     [:args,
      :a,
      [:masgn,
       [:array,
        [:lasgn, :b],
        [:masgn, [:array, [:lasgn, :c], [:splat, [:lasgn, :d]]]],
        [:splat, [:lasgn, :e]]]],
      [:block, [:lasgn, :a, [:lit, 1]]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(a=1, (b), (c)) end
    ruby

    [:defn,
     :m,
     [:args,
      :a,
      [:masgn, [:array, [:lasgn, :b]]],
      [:masgn, [:array, [:lasgn, :c]]],
      [:block, [:lasgn, :a, [:lit, 1]]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(a=1, (*b), (*c)) end
    ruby

    [:defn,
     :m,
     [:args,
      :a,
      [:masgn, [:array, [:splat, [:lasgn, :b]]]],
      [:masgn, [:array, [:splat, [:lasgn, :c]]]],
      [:block, [:lasgn, :a, [:lit, 1]]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(a=1, (b, c), (d, e)) end
    ruby

    [:defn,
     :m,
     [:args,
      :a,
      [:masgn, [:array, [:lasgn, :b], [:lasgn, :c]]],
      [:masgn, [:array, [:lasgn, :d], [:lasgn, :e]]],
      [:block, [:lasgn, :a, [:lit, 1]]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(a=1, (b, *c), (*d, e)) end
    ruby

    [:defn,
     :m,
     [:args,
      :a,
      [:masgn, [:array, [:lasgn, :b], [:splat, [:lasgn, :c]]]],
      [:masgn, [:array, [:splat, [:lasgn, :d]]], [:lasgn, :e]],
      [:block, [:lasgn, :a, [:lit, 1]]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(a=1, (b, *c), (d, (*e, f))) end
    ruby

    [:defn,
     :m,
     [:args,
      :a,
      [:masgn, [:array, [:lasgn, :b], [:splat, [:lasgn, :c]]]],
      [:masgn,
       [:array,
        [:lasgn, :d],
        [:masgn, [:array, [:splat, [:lasgn, :e]]], [:lasgn, :f]]]],
      [:block, [:lasgn, :a, [:lit, 1]]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(a=1, b:) end
    ruby

    [:defn,
     :m,
     [:args, :a, :b, [:block, [:lasgn, :a, [:lit, 1]]], [:block, [:b]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(a=1, b: 2) end
    ruby

    [:defn,
     :m,
     [:args,
      :a,
      :b,
      [:block, [:lasgn, :a, [:lit, 1]]],
      [:block, [:b], [[:lasgn, :b, [:lit, 2]]]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(a=1, **) end
    ruby

    [:defn,
     :m,
     [:args, :a, :**, [:block, [:lasgn, :a, [:lit, 1]]], [:block, [:**]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(a=1, **k) end
    ruby

    [:defn,
     :m,
     [:args, :a, :"**k", [:block, [:lasgn, :a, [:lit, 1]]], [:block, [:"**k"]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(a=1, &b) end
    ruby

    [:defn,
     :m,
     [:args, :a, :"&b", [:block, [:lasgn, :a, [:lit, 1]]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(*, a) end
    ruby

    [:defn, :m, [:args, :*, :a], [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(*a, b) end
    ruby

    [:defn, :m, [:args, :"*a", :b], [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(*, a:) end
    ruby

    [:defn, :m, [:args, :*, :a, [:block, [:a]]], [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(*a, b:) end
    ruby

    [:defn, :m, [:args, :"*a", :b, [:block, [:b]]], [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(*, a: 1) end
    ruby

    [:defn,
     :m,
     [:args, :*, :a, [:block, [:a], [[:lasgn, :a, [:lit, 1]]]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(*a, b: 1) end
    ruby

    [:defn,
     :m,
     [:args, :"*a", :b, [:block, [:b], [[:lasgn, :b, [:lit, 1]]]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(*, **) end
    ruby

    [:defn, :m, [:args, :*, :**, [:block, [:**]]], [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(*a, **) end
    ruby

    [:defn, :m, [:args, :"*a", :**, [:block, [:**]]], [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(*, **k) end
    ruby

    [:defn,
     :m,
     [:args, :*, :"**k", [:block, [:"**k"]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(*a, **k) end
    ruby

    [:defn,
     :m,
     [:args, :"*a", :"**k", [:block, [:"**k"]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(*, &b) end
    ruby

    [:defn, :m, [:args, :*, :"&b"], [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(*a, &b) end
    ruby

    [:defn, :m, [:args, :"*a", :"&b"], [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(a:, b:) end
    ruby

    [:defn, :m, [:args, :a, :b, [:block, [:a, :b]]], [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(a:, b: 1) end
    ruby

    [:defn,
     :m,
     [:args, :a, :b, [:block, [:a, :b], [[:lasgn, :b, [:lit, 1]]]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(a:, **) end
    ruby

    [:defn, :m, [:args, :a, :**, [:block, [:a, :**]]], [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(a:, **k) end
    ruby

    [:defn,
     :m,
     [:args, :a, :"**k", [:block, [:a, :"**k"]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(a:, &b) end
    ruby

    [:defn, :m, [:args, :a, :"&b", [:block, [:a]]], [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(a: 1, b:) end
    ruby

    [:defn,
     :m,
     [:args, :a, :b, [:block, [:a, :b], [[:lasgn, :a, [:lit, 1]]]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(a: def m(a: 1) a end, b:) end
    ruby

    [:defn,
     :m,
     [:args,
      :a,
      :b,
      [:block,
       [:a, :b],
       [[:lasgn,
         :a,
         [:defn,
          :m,
          [:args, :a, [:block, [:a], [[:lasgn, :a, [:lit, 1]]]]],
          [:scope, [:block, [:lvar, :a]]]]]]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(a: 1, b: 2) end
    ruby

    [:defn,
     :m,
     [:args,
      :a,
      :b,
      [:block, [:a, :b], [[:lasgn, :a, [:lit, 1]], [:lasgn, :b, [:lit, 2]]]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(a: 1, **) end
    ruby

    [:defn,
     :m,
     [:args, :a, :**, [:block, [:a, :**], [[:lasgn, :a, [:lit, 1]]]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(a: 1, **k) end
    ruby

    [:defn,
     :m,
     [:args, :a, :"**k", [:block, [:a, :"**k"], [[:lasgn, :a, [:lit, 1]]]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(a: 1, &b) end
    ruby

    [:defn,
     :m,
     [:args, :a, :"&b", [:block, [:a], [[:lasgn, :a, [:lit, 1]]]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(**, &b) end
    ruby

    [:defn, :m, [:args, :**, :"&b", [:block, [:**]]], [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(**k, &b) end
    ruby

    [:defn,
     :m,
     [:args, :"**k", :"&b", [:block, [:"**k"]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m(a, b=1, *c, d, e:, f: 2, g:, **k, &l) end
    ruby

    [:defn,
     :m,
     [:args,
      :a,
      :b,
      :"*c",
      :d,
      :e,
      :f,
      :g,
      :"**k",
      :"&l",
      [:block, [:lasgn, :b, [:lit, 1]]],
      [:block, [:e, :f, :g, :"**k"], [[:lasgn, :f, [:lit, 2]]]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m a, b=1, *c, d, e:, f: 2, g:, **k, &l
      end
    ruby

    [:defn,
     :m,
     [:args,
      :a,
      :b,
      :"*c",
      :d,
      :e,
      :f,
      :g,
      :"**k",
      :"&l",
      [:block, [:lasgn, :b, [:lit, 1]]],
      [:block, [:e, :f, :g, :"**k"], [[:lasgn, :f, [:lit, 2]]]]],
     [:scope, [:block, [:nil]]]]
  end
end
