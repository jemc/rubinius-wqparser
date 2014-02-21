describe "A Defn node" do
  parse <<-ruby do
      def m
        begin
        end
      end
    ruby

    [:defn, :m, [:args], [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def m
        return :a
      ensure
        return :b
      end
    ruby

    [:defn,
     :m,
     [:args],
     [:scope, [:block, [:ensure, [:return, [:lit, :a]], [:return, [:lit, :b]]]]]]
  end

  parse <<-ruby do
      def blah(*args, &block)
        other(42, *args, &block)
      end
    ruby

    [:defn,
     :blah,
     [:args, :"*args", :"&block"],
     [:scope,
      [:block,
       [:call,
        nil,
        :other,
        [:arglist,
         [:lit, 42],
         [:splat, [:lvar, :args]],
         [:block_pass, [:lvar, :block]]]]]]]
  end

  parse <<-ruby do
      def blah(*args, &block)
        other(*args, &block)
      end
    ruby

    [:defn,
     :blah,
     [:args, :"*args", :"&block"],
     [:scope,
      [:block,
       [:call,
        nil,
        :other,
        [:arglist,
         [:splat, [:lvar, :args]],
         [:block_pass, [:lvar, :block]]]]]]]
  end

  parse <<-ruby do
      def f
        begin
          b
        rescue
          c
        end

        d
      end
    ruby

    [:defn,
     :f,
     [:args],
     [:scope,
      [:block,
       [:rescue,
        [:call, nil, :b, [:arglist]],
        [:resbody,
         [:array, [:const, :StandardError]],
         [:call, nil, :c, [:arglist]]]],
       [:call, nil, :d, [:arglist]]]]]
  end

  parse <<-ruby do
      def f
        a
        begin
          b
        rescue
          c
        end
      end
    ruby

    [:defn,
     :f,
     [:args],
     [:scope,
      [:block,
       [:call, nil, :a, [:arglist]],
       [:rescue,
        [:call, nil, :b, [:arglist]],
        [:resbody,
         [:array, [:const, :StandardError]],
         [:call, nil, :c, [:arglist]]]]]]]
  end

  parse <<-ruby do
      def f
        a
        begin
          b
        rescue
          c
        end
        d
      end
    ruby

    [:defn,
     :f,
     [:args],
     [:scope,
      [:block,
       [:call, nil, :a, [:arglist]],
       [:rescue,
        [:call, nil, :b, [:arglist]],
        [:resbody,
         [:array, [:const, :StandardError]],
         [:call, nil, :c, [:arglist]]]],
       [:call, nil, :d, [:arglist]]]]]
  end

  parse <<-ruby do
      def f(&block)
      end
    ruby

    [:defn, :f, [:args, :"&block"], [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def f(mand, opt = 42, &block)
      end
    ruby

    [:defn,
     :f,
     [:args, :mand, :opt, :"&block", [:block, [:lasgn, :opt, [:lit, 42]]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def f(x, a=x.b)
      end
    ruby

    [:defn,
     :f,
     [:args, :x, :a, [:block, [:lasgn, :a, [:call, [:lvar, :x], :b, [:arglist]]]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def f(mand, &block)
      end
    ruby

    [:defn, :f, [:args, :mand, :"&block"], [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def f(mand, opt = 42)
      end
    ruby

    [:defn,
     :f,
     [:args, :mand, :opt, [:block, [:lasgn, :opt, [:lit, 42]]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def f(mand, opt = 42, *rest, &block)
      end
    ruby

    [:defn,
     :f,
     [:args,
      :mand,
      :opt,
      :"*rest",
      :"&block",
      [:block, [:lasgn, :opt, [:lit, 42]]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def x(a, b = 42, *)
      end
    ruby

    [:defn,
     :x,
     [:args, :a, :b, :*, [:block, [:lasgn, :b, [:lit, 42]]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def f(mand, opt = 42, *rest)
      end
    ruby

    [:defn,
     :f,
     [:args, :mand, :opt, :"*rest", [:block, [:lasgn, :opt, [:lit, 42]]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def empty
      end
    ruby

    [:defn, :empty, [:args], [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def f(mand)
      end
    ruby

    [:defn, :f, [:args, :mand], [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def f(mand, *rest, &block)
      end
    ruby

    [:defn, :f, [:args, :mand, :"*rest", :"&block"], [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def x(a, *args)
        p(a, args)
      end
    ruby

    [:defn,
     :x,
     [:args, :a, :"*args"],
     [:scope, [:block, [:call, nil, :p, [:arglist, [:lvar, :a], [:lvar, :args]]]]]]
  end

  parse <<-ruby do
      def f(mand, *rest)
      end
    ruby

    [:defn, :f, [:args, :mand, :"*rest"], [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def f(opt = 42, &block)
      end
    ruby

    [:defn,
     :f,
     [:args, :opt, :"&block", [:block, [:lasgn, :opt, [:lit, 42]]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def f(a = 42, b = '1', c=lambda {|n| n })
      end
    ruby

    [:defn,
     :f,
     [:args,
      :a,
      :b,
      :c,
      [:block,
       [:lasgn, :a, [:lit, 42]],
       [:lasgn, :b, [:str, "1"]],
       [:lasgn,
        :c,
        [:call, nil, :lambda, [:arglist, [:iter, [:args, :n], [:lvar, :n]]]]]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def f(opt = 42)
      end
    ruby

    [:defn,
     :f,
     [:args, :opt, [:block, [:lasgn, :opt, [:lit, 42]]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def f(opt = 42, *rest, &block)
      end
    ruby

    [:defn,
     :f,
     [:args, :opt, :"*rest", :"&block", [:block, [:lasgn, :opt, [:lit, 42]]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def x(b = 42, *)
      end
    ruby

    [:defn,
     :x,
     [:args, :b, :*, [:block, [:lasgn, :b, [:lit, 42]]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def f(opt = 42, *rest)
      end
    ruby

    [:defn,
     :f,
     [:args, :opt, :"*rest", [:block, [:lasgn, :opt, [:lit, 42]]]],
     [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def |(o)
      end
    ruby

    [:defn, :|, [:args, :o], [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def eql?(resource)
        (self.uuid == resource.uuid)
      rescue
        false
      end
    ruby

    [:defn,
     :eql?,
     [:args, :resource],
     [:scope,
      [:block,
       [:rescue,
        [:call,
         [:call, [:self], :uuid, [:arglist]],
         :==,
         [:arglist, [:call, [:lvar, :resource], :uuid, [:arglist]]]],
        [:resbody, [:array, [:const, :StandardError]], [:false]]]]]]
  end

  parse <<-ruby do
      def something?
      end
    ruby

    [:defn, :something?, [:args], [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def x(*)
      end
    ruby

    [:defn, :x, [:args, :*], [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def f(*rest)
      end
    ruby

    [:defn, :f, [:args, :"*rest"], [:scope, [:block, [:nil]]]]
  end

  parse <<-ruby do
      def x(a, *)
        p(a)
      end
    ruby

    [:defn,
     :x,
     [:args, :a, :*],
     [:scope, [:block, [:call, nil, :p, [:arglist, [:lvar, :a]]]]]]
  end

  parse <<-ruby do
      def zarray
        a = []
        return a
      end
    ruby

    [:defn,
     :zarray,
     [:args],
     [:scope, [:block, [:lasgn, :a, [:array]], [:return, [:lvar, :a]]]]]
  end

  parse <<-ruby do
      b = 42
      def a
        c do
          begin
            do_stuff
          rescue RuntimeError => b
            puts(b)
          end
        end
      end
    ruby

    [:block,
     [:lasgn, :b, [:lit, 42]],
     [:defn,
      :a,
      [:args],
      [:scope,
       [:block,
        [:call,
         nil,
         :c,
         [:arglist,
          [:iter,
           [:args],
           [:rescue,
            [:call, nil, :do_stuff, [:arglist]],
            [:resbody,
             [:array, [:const, :RuntimeError], [:lasgn, :b, [:gvar, :$!]]],
             [:call, nil, :puts, [:arglist, [:lvar, :b]]]]]]]]]]]]
  end

  parse <<-ruby do
      def x(a=0.0,b=0.0)
        a+b
      end
    ruby

    [:defn,
     :x,
     [:args,
      :a,
      :b,
      [:block, [:lasgn, :a, [:lit, 0.0]], [:lasgn, :b, [:lit, 0.0]]]],
     [:scope, [:block, [:call, [:lvar, :a], :+, [:arglist, [:lvar, :b]]]]]]
  end

  parse <<-ruby do
      def x(*b)
        a(*b)
      end
    ruby

    [:defn,
     :x,
     [:args, :"*b"],
     [:scope, [:block, [:call, nil, :a, [:arglist, [:splat, [:lvar, :b]]]]]]]
  end

  parse <<-ruby do
      def meth(b)
        b
      end
    ruby

    [:defn, :meth, [:args, :b], [:scope, [:block, [:lvar, :b]]]]
  end
end
