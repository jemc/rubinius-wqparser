describe "An Iter node" do
  parse "m { }" do
    [:call, nil, :m, [:arglist, [:iter, [:args], [:nil]]]]
  end

  parse "m do end" do
    [:call, nil, :m, [:arglist, [:iter, [:args], [:nil]]]]
  end

  parse "m { x }" do
    [:call, nil, :m, [:arglist, [:iter, [:args], [:call, nil, :x, [:arglist]]]]]
  end

  parse "m { || x }" do
    [:call, nil, :m, [:arglist, [:iter, [:args], [:call, nil, :x, [:arglist]]]]]
  end

  parse "m { |a| a + x }" do
    [:call,
     nil,
     :m,
     [:arglist,
      [:iter,
       [:args, :a],
       [:call, [:lvar, :a], :+, [:arglist, [:call, nil, :x, [:arglist]]]]]]]
  end

  parse "m { |*| x }" do
    [:call,
     nil,
     :m,
     [:arglist, [:iter, [:args, :*], [:call, nil, :x, [:arglist]]]]]
  end

  parse "m { |*c| x; c }" do
    [:call,
     nil,
     :m,
     [:arglist,
      [:iter,
       [:args, :"*c"],
       [:block, [:call, nil, :x, [:arglist]], [:lvar, :c]]]]]
  end

  parse "m { |a, | a + x }" do
    [:call,
     nil,
     :m,
     [:arglist,
      [:iter,
       [:args, :a],
       [:call, [:lvar, :a], :+, [:arglist, [:call, nil, :x, [:arglist]]]]]]]
  end

  parse "m { |a, *| a + x }" do
    [:call,
     nil,
     :m,
     [:arglist,
      [:iter,
       [:args, :a, :*],
       [:call, [:lvar, :a], :+, [:arglist, [:call, nil, :x, [:arglist]]]]]]]
  end

  parse "m { |a, *c| a + x; c }" do
    [:call,
     nil,
     :m,
     [:arglist,
      [:iter,
       [:args, :a, :"*c"],
       [:block,
        [:call, [:lvar, :a], :+, [:arglist, [:call, nil, :x, [:arglist]]]],
        [:lvar, :c]]]]]
  end

  parse "m { |a, b| a + x; b }" do
    [:call,
     nil,
     :m,
     [:arglist,
      [:iter,
       [:args, :a, :b],
       [:block,
        [:call, [:lvar, :a], :+, [:arglist, [:call, nil, :x, [:arglist]]]],
        [:lvar, :b]]]]]
  end

  parse "m { |a, b, | a + x; b }" do
    [:call,
     nil,
     :m,
     [:arglist,
      [:iter,
       [:args, :a, :b],
       [:block,
        [:call, [:lvar, :a], :+, [:arglist, [:call, nil, :x, [:arglist]]]],
        [:lvar, :b]]]]]
  end

  parse "m { |a, b, *| a + x; b }" do
    [:call,
     nil,
     :m,
     [:arglist,
      [:iter,
       [:args, :a, :b, :*],
       [:block,
        [:call, [:lvar, :a], :+, [:arglist, [:call, nil, :x, [:arglist]]]],
        [:lvar, :b]]]]]
  end

  masgn_rest_arg_block = lambda do |g|
    g.push :self

    g.in_block_send :m, :rest, -3 do |d|
      d.push_local 0
      d.push :self
      d.send :x, 0, true
      d.send :+, 1, false
      d.pop
      d.push_local 1
      d.pop
      d.push_local 2
    end
  end

  parse "m { |a, b, *c| a + x; b; c }" do
    [:call,
     nil,
     :m,
     [:arglist,
      [:iter,
       [:args, :a, :b, :"*c"],
       [:block,
        [:call, [:lvar, :a], :+, [:arglist, [:call, nil, :x, [:arglist]]]],
        [:lvar, :b],
        [:lvar, :c]]]]]
  end

  parse "m do |a, b, *c| a + x; b; c end" do
    [:call,
     nil,
     :m,
     [:arglist,
      [:iter,
       [:args, :a, :b, :"*c"],
       [:block,
        [:call, [:lvar, :a], :+, [:arglist, [:call, nil, :x, [:arglist]]]],
        [:lvar, :b],
        [:lvar, :c]]]]]
  end

  parse "m { n = 1; n }" do
    [:call,
     nil,
     :m,
     [:arglist, [:iter, [:args], [:block, [:lasgn, :n, [:lit, 1]], [:lvar, :n]]]]]
  end

  parse "m { n = 1; m { n } }" do
    [:call,
     nil,
     :m,
     [:arglist,
      [:iter,
       [:args],
       [:block,
        [:lasgn, :n, [:lit, 1]],
        [:call, nil, :m, [:arglist, [:iter, [:args], [:lvar, :n]]]]]]]]
  end

  parse "n = 1; m { n = 2 }; n" do
    [:block,
     [:lasgn, :n, [:lit, 1]],
     [:call, nil, :m, [:arglist, [:iter, [:args], [:lasgn, :n, [:lit, 2]]]]],
     [:lvar, :n]]
  end

  parse "m(a) { |b| a + x }" do
    [:call,
     nil,
     :m,
     [:arglist,
      [:call, nil, :a, [:arglist]],
      [:iter,
       [:args, :b],
       [:call,
        [:call, nil, :a, [:arglist]],
        :+,
        [:arglist, [:call, nil, :x, [:arglist]]]]]]]
  end

  parse <<-ruby do
      m { |a|
        a + x
      }
    ruby

    [:call,
     nil,
     :m,
     [:arglist,
      [:iter,
       [:args, :a],
       [:call, [:lvar, :a], :+, [:arglist, [:call, nil, :x, [:arglist]]]]]]]
  end

  parse <<-ruby do
      m do |a|
        a + x
      end
    ruby

    [:call,
     nil,
     :m,
     [:arglist,
      [:iter,
       [:args, :a],
       [:call, [:lvar, :a], :+, [:arglist, [:call, nil, :x, [:arglist]]]]]]]
  end

  parse "obj.m { |a| a + x }" do
    [:call,
     [:call, nil, :obj, [:arglist]],
     :m,
     [:arglist,
      [:iter,
       [:args, :a],
       [:call, [:lvar, :a], :+, [:arglist, [:call, nil, :x, [:arglist]]]]]]]
  end

  parse "obj.m(x) { |a| a + x }" do
    [:call,
     [:call, nil, :obj, [:arglist]],
     :m,
     [:arglist,
      [:call, nil, :x, [:arglist]],
      [:iter,
       [:args, :a],
       [:call, [:lvar, :a], :+, [:arglist, [:call, nil, :x, [:arglist]]]]]]]
  end

  parse "obj.m(a) { |a| a + x }" do
    [:call,
     [:call, nil, :obj, [:arglist]],
     :m,
     [:arglist,
      [:call, nil, :a, [:arglist]],
      [:iter,
       [:args, :a],
       [:call, [:lvar, :a], :+, [:arglist, [:call, nil, :x, [:arglist]]]]]]]
  end

  parse "a = 1; m { |a| a + x }" do
    [:block,
     [:lasgn, :a, [:lit, 1]],
     [:call,
      nil,
      :m,
      [:arglist,
       [:iter,
        [:args, :a],
        [:call, [:lvar, :a], :+, [:arglist, [:call, nil, :x, [:arglist]]]]]]]]
  end

  parse <<-ruby do
      x = nil
      m do |a|
        begin
          x
        rescue Exception => x
          break
        ensure
          x = a
        end
      end
    ruby

    [:block,
     [:lasgn, :x, [:nil]],
     [:call,
      nil,
      :m,
      [:arglist,
       [:iter,
        [:args, :a],
        [:ensure,
         [:rescue,
          [:lvar, :x],
          [:resbody,
           [:array, [:const, :Exception], [:lasgn, :x, [:gvar, :$!]]],
           [:break, [:nil]]]],
         [:lasgn, :x, [:lvar, :a]]]]]]]
  end

  parse "m { next }" do
    [:call, nil, :m, [:arglist, [:iter, [:args], [:next]]]]
  end

  parse "m { next if x }" do
    [:call,
     nil,
     :m,
     [:arglist,
      [:iter, [:args], [:if, [:call, nil, :x, [:arglist]], [:next], nil]]]]
  end

  parse "m { next x }" do
    [:call,
     nil,
     :m,
     [:arglist, [:iter, [:args], [:next, [:call, nil, :x, [:arglist]]]]]]
  end

  parse "m { x = 1; next x }" do
    [:call,
     nil,
     :m,
     [:arglist,
      [:iter, [:args], [:block, [:lasgn, :x, [:lit, 1]], [:next, [:lvar, :x]]]]]]
  end

  parse "m { next [1] }" do
    [:call, nil, :m, [:arglist, [:iter, [:args], [:next, [:array, [:lit, 1]]]]]]
  end

  parse "m { next *[1] }" do
    [:call,
     nil,
     :m,
     [:arglist, [:iter, [:args], [:next, [:splat, [:array, [:lit, 1]]]]]]]
  end

  parse "m { next [*[1]] }" do
    [:call,
     nil,
     :m,
     [:arglist, [:iter, [:args], [:next, [:splat, [:array, [:lit, 1]]]]]]]
  end

  parse "m { next *[1, 2] }" do
    [:call,
     nil,
     :m,
     [:arglist,
      [:iter, [:args], [:next, [:splat, [:array, [:lit, 1], [:lit, 2]]]]]]]
  end

  parse "m { next [*[1, 2]] }" do
    [:call,
     nil,
     :m,
     [:arglist,
      [:iter, [:args], [:next, [:splat, [:array, [:lit, 1], [:lit, 2]]]]]]]
  end

  parse "m { break }" do
    [:call, nil, :m, [:arglist, [:iter, [:args], [:break, [:nil]]]]]
  end

  parse "m { break if x }" do
    [:call,
     nil,
     :m,
     [:arglist,
      [:iter,
       [:args],
       [:if, [:call, nil, :x, [:arglist]], [:break, [:nil]], nil]]]]
  end

  parse "m { break x }" do
    [:call,
     nil,
     :m,
     [:arglist, [:iter, [:args], [:break, [:call, nil, :x, [:arglist]]]]]]
  end

  parse "m { x = 1; break x }" do
    [:call,
     nil,
     :m,
     [:arglist,
      [:iter, [:args], [:block, [:lasgn, :x, [:lit, 1]], [:break, [:lvar, :x]]]]]]
  end

  parse "m { break [1] }" do
    [:call, nil, :m, [:arglist, [:iter, [:args], [:break, [:array, [:lit, 1]]]]]]
  end

  parse "m { break *[1] }" do
    [:call,
     nil,
     :m,
     [:arglist, [:iter, [:args], [:break, [:splat, [:array, [:lit, 1]]]]]]]
  end

  parse "m { break [*[1]] }" do
    [:call,
     nil,
     :m,
     [:arglist, [:iter, [:args], [:break, [:splat, [:array, [:lit, 1]]]]]]]
  end

  parse "m { break *[1, 2] }" do
    [:call,
     nil,
     :m,
     [:arglist,
      [:iter, [:args], [:break, [:splat, [:array, [:lit, 1], [:lit, 2]]]]]]]
  end

  parse "m { break [*[1, 2]] }" do
    [:call,
     nil,
     :m,
     [:arglist,
      [:iter, [:args], [:break, [:splat, [:array, [:lit, 1], [:lit, 2]]]]]]]
  end

  parse "m { return }" do
    [:call, nil, :m, [:arglist, [:iter, [:args], [:return]]]]
  end

  parse "m { return if x }" do
    [:call,
     nil,
     :m,
     [:arglist,
      [:iter, [:args], [:if, [:call, nil, :x, [:arglist]], [:return], nil]]]]
  end

  parse "m { return x }" do
    [:call,
     nil,
     :m,
     [:arglist, [:iter, [:args], [:return, [:call, nil, :x, [:arglist]]]]]]
  end

  parse "m { x = 1; return x }" do
    [:call,
     nil,
     :m,
     [:arglist,
      [:iter, [:args], [:block, [:lasgn, :x, [:lit, 1]], [:return, [:lvar, :x]]]]]]
  end

  parse "m { return [1] }" do
    [:call, nil, :m, [:arglist, [:iter, [:args], [:return, [:array, [:lit, 1]]]]]]
  end

  parse "m { return *[1] }" do
    [:call,
     nil,
     :m,
     [:arglist, [:iter, [:args], [:return, [:splat, [:array, [:lit, 1]]]]]]]
  end

  parse "m { return [*[1]] }" do
    [:call,
     nil,
     :m,
     [:arglist, [:iter, [:args], [:return, [:splat, [:array, [:lit, 1]]]]]]]
  end

  parse "m { return *[1, 2] }" do
    [:call,
     nil,
     :m,
     [:arglist,
      [:iter, [:args], [:return, [:splat, [:array, [:lit, 1], [:lit, 2]]]]]]]
  end

  parse "m { return [*[1, 2]] }" do
    [:call,
     nil,
     :m,
     [:arglist,
      [:iter, [:args], [:return, [:splat, [:array, [:lit, 1], [:lit, 2]]]]]]]
  end

  parse "m { redo }" do
    [:call, nil, :m, [:arglist, [:iter, [:args], [:redo]]]]
  end

  parse "m { redo if x }" do
    [:call,
     nil,
     :m,
     [:arglist,
      [:iter, [:args], [:if, [:call, nil, :x, [:arglist]], [:redo], nil]]]]
  end

  parse "m(a) { retry }" do
    [:call,
     nil,
     :m,
     [:arglist, [:call, nil, :a, [:arglist]], [:iter, [:args], [:retry]]]]
  end

  parse "m(a) { retry if x }" do
    [:call,
     nil,
     :m,
     [:arglist,
      [:call, nil, :a, [:arglist]],
      [:iter, [:args], [:if, [:call, nil, :x, [:arglist]], [:retry], nil]]]]
  end

  parse "break" do
    [:break, [:nil]]
  end

  parse "redo" do
    [:redo]
  end

  parse "retry" do
    [:retry]
  end

  parse "next" do
    [:next]
  end

  parse <<-ruby do
      def x(a)
        bar { super }
      end
    ruby

    [:defn,
     :x,
     [:args, :a],
     [:scope,
      [:block, [:call, nil, :bar, [:arglist, [:iter, [:args], [:zsuper]]]]]]]
  end
end
