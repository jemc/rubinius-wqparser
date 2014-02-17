describe "A Defs node" do
  parse <<-ruby do
      def self.x(y)
        (y + 1)
      end
    ruby

    [:defs,
       [:self],
       :x,
       [:args, :y],
       [:scope, [:block, [:call, [:lvar, :y], :+, [:arglist, [:lit, 1]]]]]]
  end

  parse <<-ruby do
      def self.setup(ctx)
        bind = allocate
        bind.context = ctx
        return bind
      end
    ruby

    [:defs,
       [:self],
       :setup,
       [:args, :ctx],
       [:scope,
        [:block,
         [:lasgn, :bind, [:call, nil, :allocate, [:arglist]]],
         [:attrasgn, [:lvar, :bind], :context=, [:arglist, [:lvar, :ctx]]],
         [:return, [:lvar, :bind]]]]]
  end

  parse <<-ruby do
      def self.empty(*)
      end
    ruby

    [:defs, [:self], :empty, [:args, :*], [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def self.empty
      end
    ruby

    [:defs, [:self], :empty, [:args], [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def (a.b).empty(*)
      end
    ruby

    [:defs,
     [:call, [:call, nil, :a, [:arglist]], :b, [:arglist]],
     :empty,
     [:args, :*],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
    x = "a"
    def x.m(a)
      a
    end
    ruby

    [:block,
     [:lasgn, :x, [:str, "a"]],
     [:defs, [:lvar, :x], :m, [:args, :a], [:scope, [:block, [:lvar, :a]]]]]
  end
end
