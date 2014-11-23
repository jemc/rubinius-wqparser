describe "An AST node" do
  # test_hash_label
  parse "{ foo: 2 }" do
    [:hash, [:lit, :foo], [:lit, 2]]
  end
  
  # test_masgn_const
  parse "self::A, foo = foo" do
    [:masgn,
     [:array, [:cdecl, [:colon2, [:self], :A]], [:lasgn, :foo]],
     [:lvar, :foo]]
  end
  
  # test_masgn_const
  parse "::A, foo = foo" do
    [:masgn, [:array, [:cdecl, [:colon3, :A]], [:lasgn, :foo]], [:lvar, :foo]]
  end
  
  # test_arg_scope
  parse "def f(var = defined?(var)) var end" do
    [:defn,
     :f,
     [:args,
      :var,
      [:block, [:lasgn, :var, [:defined, [:call, nil, :var, [:arglist]]]]]],
     [:scope, [:block, [:lvar, :var]]]]
  end
  
  # test_arg_scope
  parse "def f(var: defined?(var)) var end" do
    [:defn,
     :f,
     [:args, :var, [:kwargs, [:var], [[:lasgn, :var, [:defined, [:lvar, :var]]]]]],
     [:scope, [:block, [:lvar, :var]]]]
  end
  
  # test_zsuper
  parse "super" do
    [:zsuper]
  end
  
  # test_when_multi
  parse "case foo; when 'bar', 'baz'; bar; end" do
    [:case,
     [:call, nil, :foo, [:arglist]],
     [:when,
      [:array, [:str, "bar"], [:str, "baz"]],
      [:call, nil, :bar, [:arglist]]],
     nil]
  end
  
  # # ERROR in: test_regexp_encoding
  # parse "/\\xa8/n =~ \"\""
  
  # # ERROR in: test_hash_label_end
  # parse "{ 'foo': 2 }"
  
  # test_hash_label_end
  parse "f(a ? \"a\":1)" do
    [:call,
     nil,
     :f,
     [:arglist, [:if, [:call, nil, :a, [:arglist]], [:str, "a"], [:lit, 1]]]]
  end
  
  # test_super_block
  parse "super foo, bar do end" do
    [:super,
     [:call, nil, :foo, [:arglist]],
     [:call, nil, :bar, [:arglist]],
     [:iter, [:args], [:nil]]]
  end
  
  # test_super_block
  parse "super do end" do
    [:zsuper]
  end
  
  # test_when_splat
  parse "case foo; when 1, *baz; bar; when *foo; end" do
    [:case,
     [:call, nil, :foo, [:arglist]],
     [:when,
      [:array, [:lit, 1], [:when, [:call, nil, :baz, [:arglist]], nil]],
      [:call, nil, :bar, [:arglist]]],
     [:when, [[:when, [:call, nil, :foo, [:arglist]], nil]], [:nil]],
     nil]
  end
  
  # test_hash_kwsplat
  parse "{ foo: 2, **bar }" do
    [:hash, [:lit, :foo], [:lit, 2], [:hash_splat], [:call, nil, :bar, [:arglist]]]
  end
  
  # test_masgn_cmd
  parse "foo, bar = m foo" do
    [:masgn,
     [:array, [:lasgn, :foo], [:lasgn, :bar]],
     [:call, nil, :m, [:arglist, [:lvar, :foo]]]]
  end
  
  # test_yield
  parse "yield(foo)" do
    [:yield, [:call, nil, :foo, [:arglist]]]
  end
  
  # test_yield
  parse "yield foo" do
    [:yield, [:call, nil, :foo, [:arglist]]]
  end
  
  # test_yield
  parse "yield()" do
    [:yield]
  end
  
  # test_yield
  parse "yield" do
    [:yield]
  end
  
  # test_while
  parse "while foo do meth end" do
    [:while, [:call, nil, :foo, [:arglist]], [:call, nil, :meth, [:arglist]], true]
  end
  
  # test_while
  parse "while foo; meth end" do
    [:while, [:call, nil, :foo, [:arglist]], [:call, nil, :meth, [:arglist]], true]
  end
  
  # test_asgn_mrhs
  parse "foo = bar, 1" do
    [:lasgn, :foo, [:array, [:call, nil, :bar, [:arglist]], [:lit, 1]]]
  end
  
  # test_asgn_mrhs
  parse "foo = *bar" do
    [:lasgn, :foo, [:splat, [:call, nil, :bar, [:arglist]]]]
  end
  
  # test_asgn_mrhs
  parse "foo = baz, *bar" do
    [:lasgn,
     :foo,
     [:argscat,
      [:array, [:call, nil, :baz, [:arglist]]],
      [:call, nil, :bar, [:arglist]]]]
  end
  
  # test_arg_combinations
  parse "def f a, o=1, *r, &b; end" do
    [:defn,
     :f,
     [:args, :a, :o, :"*r", :"&b", [:block, [:lasgn, :o, [:lit, 1]]]],
     [:scope, [:block, [:nil]]]]
  end
  
  # test_arg_combinations
  parse "def f a, o=1, *r, p, &b; end" do
    [:defn,
     :f,
     [:args, :a, :o, :"*r", :p, :"&b", [:block, [:lasgn, :o, [:lit, 1]]]],
     [:scope, [:block, [:nil]]]]
  end
  
  # test_arg_combinations
  parse "def f a, o=1, &b; end" do
    [:defn,
     :f,
     [:args, :a, :o, :"&b", [:block, [:lasgn, :o, [:lit, 1]]]],
     [:scope, [:block, [:nil]]]]
  end
  
  # test_arg_combinations
  parse "def f a, o=1, p, &b; end" do
    [:defn,
     :f,
     [:args, :a, :o, :p, :"&b", [:block, [:lasgn, :o, [:lit, 1]]]],
     [:scope, [:block, [:nil]]]]
  end
  
  # test_arg_combinations
  parse "def f a, *r, &b; end" do
    [:defn, :f, [:args, :a, :"*r", :"&b"], [:scope, [:block, [:nil]]]]
  end
  
  # test_arg_combinations
  parse "def f a, *r, p, &b; end" do
    [:defn, :f, [:args, :a, :"*r", :p, :"&b"], [:scope, [:block, [:nil]]]]
  end
  
  # test_arg_combinations
  parse "def f a, &b; end" do
    [:defn, :f, [:args, :a, :"&b"], [:scope, [:block, [:nil]]]]
  end
  
  # test_arg_combinations
  parse "def f o=1, *r, &b; end" do
    [:defn,
     :f,
     [:args, :o, :"*r", :"&b", [:block, [:lasgn, :o, [:lit, 1]]]],
     [:scope, [:block, [:nil]]]]
  end
  
  # test_arg_combinations
  parse "def f o=1, *r, p, &b; end" do
    [:defn,
     :f,
     [:args, :o, :"*r", :p, :"&b", [:block, [:lasgn, :o, [:lit, 1]]]],
     [:scope, [:block, [:nil]]]]
  end
  
  # test_arg_combinations
  parse "def f o=1, &b; end" do
    [:defn,
     :f,
     [:args, :o, :"&b", [:block, [:lasgn, :o, [:lit, 1]]]],
     [:scope, [:block, [:nil]]]]
  end
  
  # test_arg_combinations
  parse "def f o=1, p, &b; end" do
    [:defn,
     :f,
     [:args, :o, :p, :"&b", [:block, [:lasgn, :o, [:lit, 1]]]],
     [:scope, [:block, [:nil]]]]
  end
  
  # test_arg_combinations
  parse "def f *r, &b; end" do
    [:defn, :f, [:args, :"*r", :"&b"], [:scope, [:block, [:nil]]]]
  end
  
  # test_arg_combinations
  parse "def f *r, p, &b; end" do
    [:defn, :f, [:args, :"*r", :p, :"&b"], [:scope, [:block, [:nil]]]]
  end
  
  # test_arg_combinations
  parse "def f &b; end" do
    [:defn, :f, [:args, :"&b"], [:scope, [:block, [:nil]]]]
  end
  
  # test_arg_combinations
  parse "def f ; end" do
    [:defn, :f, [:args], [:scope, [:block, [:nil]]]]
  end
  
  # test_while_mod
  parse "meth while foo" do
    [:while, [:call, nil, :foo, [:arglist]], [:call, nil, :meth, [:arglist]], true]
  end
  
  # # ERROR in: test_hash_no_hashrocket
  # parse "{ 1, 2 }"
  
  # test_kwarg_combinations
  parse "def f (foo: 1, bar: 2, **baz, &b); end" do
    [:defn,
     :f,
     [:args,
      :foo,
      :bar,
      :"**baz",
      :"&b",
      [:kwargs,
       [:foo, :bar, :"**baz"],
       [[:lasgn, :foo, [:lit, 1]], [:lasgn, :bar, [:lit, 2]]]]],
     [:scope, [:block, [:nil]]]]
  end
  
  # test_kwarg_combinations
  parse "def f (foo: 1, &b); end" do
    [:defn,
     :f,
     [:args, :foo, :"&b", [:kwargs, [:foo], [[:lasgn, :foo, [:lit, 1]]]]],
     [:scope, [:block, [:nil]]]]
  end
  
  # test_kwarg_combinations
  parse "def f **baz, &b; end" do
    [:defn,
     :f,
     [:args, :"**baz", :"&b", [:kwargs, [:"**baz"]]],
     [:scope, [:block, [:nil]]]]
  end
  
  # test_until
  parse "until foo do meth end" do
    [:until, [:call, nil, :foo, [:arglist]], [:call, nil, :meth, [:arglist]], true]
  end
  
  # test_until
  parse "until foo; meth end" do
    [:until, [:call, nil, :foo, [:arglist]], [:call, nil, :meth, [:arglist]], true]
  end
  
  # test_kwarg_no_paren
  parse "def f foo:\n; end" do
    [:defn, :f, [:args, :foo, [:kwargs, [:foo]]], [:scope, [:block, [:nil]]]]
  end
  
  # test_kwarg_no_paren
  parse "def f foo: -1\n; end" do
    [:defn,
     :f,
     [:args, :foo, [:kwargs, [:foo], [[:lasgn, :foo, [:lit, -1]]]]],
     [:scope, [:block, [:nil]]]]
  end
  
  # test_args_cmd
  parse "fun(f bar)" do
    [:call,
     nil,
     :fun,
     [:arglist, [:call, nil, :f, [:arglist, [:call, nil, :bar, [:arglist]]]]]]
  end
  
  # test_until_mod
  parse "meth until foo" do
    [:until, [:call, nil, :foo, [:arglist]], [:call, nil, :meth, [:arglist]], true]
  end
  
  # test_args_args_star
  parse "fun(foo, *bar)" do
    [:call,
     nil,
     :fun,
     [:arglist,
      [:call, nil, :foo, [:arglist]],
      [:splat, [:call, nil, :bar, [:arglist]]]]]
  end
  
  # test_args_args_star
  parse "fun(foo, *bar, &baz)" do
    [:call,
     nil,
     :fun,
     [:arglist,
      [:call, nil, :foo, [:arglist]],
      [:splat, [:call, nil, :bar, [:arglist]]],
      [:block_pass, [:call, nil, :baz, [:arglist]]]]]
  end
  
  # test_while_post
  parse "begin meth end while foo" do
    [:while,
     [:call, nil, :foo, [:arglist]],
     [:call, nil, :meth, [:arglist]],
     false]
  end
  
  # test_range_inclusive
  parse "1..2" do
    [:dot2, [:lit, 1], [:lit, 2]]
  end
  
  # test_var_op_asgn
  parse "a += 1" do
    [:lasgn, :a, [:call, [:lvar, :a], :+, [:arglist, [:lit, 1]]]]
  end
  
  # test_var_op_asgn
  parse "@a |= 1" do
    [:iasgn, :@a, [:call, [:ivar, :@a], :|, [:arglist, [:lit, 1]]]]
  end
  
  # test_var_op_asgn
  parse "@@var |= 10" do
    [:cvasgn, :@@var, [:call, [:cvar, :@@var], :|, [:arglist, [:lit, 10]]]]
  end
  
  # test_var_op_asgn
  parse "def a; @@var |= 10; end" do
    [:defn,
     :a,
     [:args],
     [:scope,
      [:block,
       [:cvasgn, :@@var, [:call, [:cvar, :@@var], :|, [:arglist, [:lit, 10]]]]]]]
  end
  
  # test_marg_combinations
  parse "def f (((a))); end" do
    [:defn,
     :f,
     [:args,
      [:masgn, [:array, [:masgn, [:array, [:lasgn, :a]]]], [:lvar, :"_:1"]]],
     [:scope, [:block, [:nil]]]]
  end
  
  # test_marg_combinations
  parse "def f ((a, a1)); end" do
    [:defn,
     :f,
     [:args, [:masgn, [:array, [:lasgn, :a], [:lasgn, :a1]], [:lvar, :"_:1"]]],
     [:scope, [:block, [:nil]]]]
  end
  
  # test_marg_combinations
  parse "def f ((a, *r)); end" do
    [:defn,
     :f,
     [:args,
      [:masgn, [:array, [:lasgn, :a], [:splat, [:lasgn, :r]]], [:lvar, :"_:1"]]],
     [:scope, [:block, [:nil]]]]
  end
  
  # test_marg_combinations
  parse "def f ((a, *r, p)); end" do
    [:defn,
     :f,
     [:args,
      [:masgn,
       [:array, [:lasgn, :a], [:splat, [:lasgn, :r]]],
       [:lasgn, :p],
       [:lvar, :"_:1"]]],
     [:scope, [:block, [:nil]]]]
  end
  
  # test_marg_combinations
  parse "def f ((a, *)); end" do
    [:defn,
     :f,
     [:args, [:masgn, [:array, [:lasgn, :a], [:splat]], [:lvar, :"_:1"]]],
     [:scope, [:block, [:nil]]]]
  end
  
  # test_marg_combinations
  parse "def f ((a, *, p)); end" do
    [:defn,
     :f,
     [:args, [:masgn, [:array, [:lasgn, :a]], [:lasgn, :p], [:lvar, :"_:1"]]],
     [:scope, [:block, [:nil]]]]
  end
  
  # test_marg_combinations
  parse "def f ((*r)); end" do
    [:defn,
     :f,
     [:args, [:masgn, [:array, [:splat, [:lasgn, :r]]], [:lvar, :"_:1"]]],
     [:scope, [:block, [:nil]]]]
  end
  
  # test_marg_combinations
  parse "def f ((*r, p)); end" do
    [:defn,
     :f,
     [:args,
      [:masgn, [:array, [:splat, [:lasgn, :r]]], [:lasgn, :p], [:lvar, :"_:1"]]],
     [:scope, [:block, [:nil]]]]
  end
  
  # test_marg_combinations
  parse "def f ((*)); end" do
    [:defn,
     :f,
     [:args, [:masgn, [:array, [:splat]], [:lvar, :"_:1"]]],
     [:scope, [:block, [:nil]]]]
  end
  
  # test_marg_combinations
  parse "def f ((*, p)); end" do
    [:defn,
     :f,
     [:args, [:masgn, [:array], [:lasgn, :p], [:lvar, :"_:1"]]],
     [:scope, [:block, [:nil]]]]
  end
  
  # test_args_star
  parse "fun(*bar)" do
    [:call, nil, :fun, [:arglist, [:splat, [:call, nil, :bar, [:arglist]]]]]
  end
  
  # test_args_star
  parse "fun(*bar, &baz)" do
    [:call,
     nil,
     :fun,
     [:arglist,
      [:splat, [:call, nil, :bar, [:arglist]]],
      [:block_pass, [:call, nil, :baz, [:arglist]]]]]
  end
  
  # test_args_block_pass
  parse "fun(&bar)" do
    [:call, nil, :fun, [:arglist, [:block_pass, [:call, nil, :bar, [:arglist]]]]]
  end
  
  # test_until_post
  parse "begin meth end until foo" do
    [:until,
     [:call, nil, :foo, [:arglist]],
     [:call, nil, :meth, [:arglist]],
     false]
  end
  
  # test_range_exclusive
  parse "1...2" do
    [:dot3, [:lit, 1], [:lit, 2]]
  end
  
  # test_block_arg_combinations
  parse "f{  }" do
    [:call, nil, :f, [:arglist, [:iter, [:args], [:nil]]]]
  end
  
  # test_block_arg_combinations
  parse "f{ | | }" do
    [:call, nil, :f, [:arglist, [:iter, [:args], [:nil]]]]
  end
  
  # test_block_arg_combinations
  parse "f{ |;a| }" do
    [:call, nil, :f, [:arglist, [:iter, [:args], [:nil]]]]
  end
  
  # # ERROR in: test_block_arg_combinations
  # parse "f{ |;\na\n| }"
  
  # test_block_arg_combinations
  parse "f{ || }" do
    [:call, nil, :f, [:arglist, [:iter, [:args], [:nil]]]]
  end
  
  # test_block_arg_combinations
  parse "f{ |a| }" do
    [:call, nil, :f, [:arglist, [:iter, [:args, :a], [:nil]]]]
  end
  
  # test_block_arg_combinations
  parse "f{ |a, c| }" do
    [:call, nil, :f, [:arglist, [:iter, [:args, :a, :c], [:nil]]]]
  end
  
  # # ERROR in: test_block_arg_combinations
  # parse "f{ |@a| }"
  
  # test_block_arg_combinations
  parse "f{ |a,| }" do
    [:call, nil, :f, [:arglist, [:iter, [:args, :a], [:nil]]]]
  end
  
  # test_block_arg_combinations
  parse "f{ |a, &b| }" do
    [:call, nil, :f, [:arglist, [:iter, [:args, :a, :"&b"], [:nil]]]]
  end
  
  # # ERROR in: test_block_arg_combinations
  # parse "f{ |a, &@b| }"
  
  # test_block_arg_combinations
  parse "f{ |a, *s, &b| }" do
    [:call, nil, :f, [:arglist, [:iter, [:args, :a, :"*s", :"&b"], [:nil]]]]
  end
  
  # # ERROR in: test_block_arg_combinations
  # parse "f{ |a, *@s, &@b| }"
  
  # test_block_arg_combinations
  parse "f{ |a, *, &b| }" do
    [:call, nil, :f, [:arglist, [:iter, [:args, :a, :*, :"&b"], [:nil]]]]
  end
  
  # # ERROR in: test_block_arg_combinations
  # parse "f{ |a, *, &@b| }"
  
  # test_block_arg_combinations
  parse "f{ |a, *s| }" do
    [:call, nil, :f, [:arglist, [:iter, [:args, :a, :"*s"], [:nil]]]]
  end
  
  # # ERROR in: test_block_arg_combinations
  # parse "f{ |a, *@s| }"
  
  # test_block_arg_combinations
  parse "f{ |a, *| }" do
    [:call, nil, :f, [:arglist, [:iter, [:args, :a, :*], [:nil]]]]
  end
  
  # test_block_arg_combinations
  parse "f{ |*s, &b| }" do
    [:call, nil, :f, [:arglist, [:iter, [:args, :"*s", :"&b"], [:nil]]]]
  end
  
  # # ERROR in: test_block_arg_combinations
  # parse "f{ |*@s, &@b| }"
  
  # test_block_arg_combinations
  parse "f{ |*, &b| }" do
    [:call, nil, :f, [:arglist, [:iter, [:args, :*, :"&b"], [:nil]]]]
  end
  
  # # ERROR in: test_block_arg_combinations
  # parse "f{ |*, &@b| }"
  
  # test_block_arg_combinations
  parse "f{ |*s| }" do
    [:call, nil, :f, [:arglist, [:iter, [:args, :"*s"], [:nil]]]]
  end
  
  # # ERROR in: test_block_arg_combinations
  # parse "f{ |*@s| }"
  
  # test_block_arg_combinations
  parse "f{ |*| }" do
    [:call, nil, :f, [:arglist, [:iter, [:args, :*], [:nil]]]]
  end
  
  # test_block_arg_combinations
  parse "f{ |&b| }" do
    [:call, nil, :f, [:arglist, [:iter, [:args, :"&b"], [:nil]]]]
  end
  
  # # ERROR in: test_block_arg_combinations
  # parse "f{ |&@b| }"
  
  # test_block_arg_combinations
  parse "f{ |a, o=1, o1=2, *r, &b| }" do
    [:call,
     nil,
     :f,
     [:arglist,
      [:iter,
       [:args,
        :a,
        :o,
        :o1,
        :"*r",
        :"&b",
        [:block, [:lasgn, :o, [:lit, 1]], [:lasgn, :o1, [:lit, 2]]]],
       [:nil]]]]
  end
  
  # test_block_arg_combinations
  parse "f{ |a, o=1, *r, p, &b| }" do
    [:call,
     nil,
     :f,
     [:arglist,
      [:iter,
       [:args, :a, :o, :"*r", :p, :"&b", [:block, [:lasgn, :o, [:lit, 1]]]],
       [:nil]]]]
  end
  
  # test_block_arg_combinations
  parse "f{ |a, o=1, &b| }" do
    [:call,
     nil,
     :f,
     [:arglist,
      [:iter, [:args, :a, :o, :"&b", [:block, [:lasgn, :o, [:lit, 1]]]], [:nil]]]]
  end
  
  # test_block_arg_combinations
  parse "f{ |a, o=1, p, &b| }" do
    [:call,
     nil,
     :f,
     [:arglist,
      [:iter,
       [:args, :a, :o, :p, :"&b", [:block, [:lasgn, :o, [:lit, 1]]]],
       [:nil]]]]
  end
  
  # test_block_arg_combinations
  parse "f{ |a, *r, p, &b| }" do
    [:call, nil, :f, [:arglist, [:iter, [:args, :a, :"*r", :p, :"&b"], [:nil]]]]
  end
  
  # test_block_arg_combinations
  parse "f{ |o=1, *r, &b| }" do
    [:call,
     nil,
     :f,
     [:arglist,
      [:iter,
       [:args, :o, :"*r", :"&b", [:block, [:lasgn, :o, [:lit, 1]]]],
       [:nil]]]]
  end
  
  # test_block_arg_combinations
  parse "f{ |o=1, *r, p, &b| }" do
    [:call,
     nil,
     :f,
     [:arglist,
      [:iter,
       [:args, :o, :"*r", :p, :"&b", [:block, [:lasgn, :o, [:lit, 1]]]],
       [:nil]]]]
  end
  
  # test_block_arg_combinations
  parse "f{ |o=1, &b| }" do
    [:call,
     nil,
     :f,
     [:arglist,
      [:iter, [:args, :o, :"&b", [:block, [:lasgn, :o, [:lit, 1]]]], [:nil]]]]
  end
  
  # test_block_arg_combinations
  parse "f{ |o=1, p, &b| }" do
    [:call,
     nil,
     :f,
     [:arglist,
      [:iter, [:args, :o, :p, :"&b", [:block, [:lasgn, :o, [:lit, 1]]]], [:nil]]]]
  end
  
  # test_block_arg_combinations
  parse "f{ |*r, p, &b| }" do
    [:call, nil, :f, [:arglist, [:iter, [:args, :"*r", :p, :"&b"], [:nil]]]]
  end
  
  # test_args_args_comma
  parse "foo[bar,]" do
    [:call,
     [:call, nil, :foo, [:arglist]],
     :[],
     [:arglist, [:call, nil, :bar, [:arglist]]]]
  end
  
  # test_var_op_asgn_cmd
  parse "foo += m foo" do
    [:lasgn,
     :foo,
     [:call,
      [:lvar, :foo],
      :+,
      [:arglist, [:call, nil, :m, [:arglist, [:lvar, :foo]]]]]]
  end
  
  # test_args_assocs
  parse "fun(:foo => 1)" do
    [:call, nil, :fun, [:arglist, [:hash, [:lit, :foo], [:lit, 1]]]]
  end
  
  # test_args_assocs
  parse "fun(:foo => 1, &baz)" do
    [:call,
     nil,
     :fun,
     [:arglist,
      [:hash, [:lit, :foo], [:lit, 1]],
      [:block_pass, [:call, nil, :baz, [:arglist]]]]]
  end
  
  # test_self
  parse "self" do
    [:self]
  end
  
  # # ERROR in: test_args_assocs_star
  # parse "fun(:foo => 1, *bar)"
  
  # # ERROR in: test_args_assocs_star
  # parse "fun(:foo => 1, *bar, &baz)"
  
  # test_lvar
  parse "foo" do
    [:call, nil, :foo, [:arglist]]
  end
  
  # test_const_op_asgn
  parse "A += 1" do
    [:cdecl, :A, [:call, [:const, :A], :+, [:arglist, [:lit, 1]]]]
  end
  
  # # ERROR in: test_const_op_asgn
  # parse "::A += 1"
  
  # # ERROR in: test_const_op_asgn
  # parse "B::A += 1"
  
  # # ERROR in: test_const_op_asgn
  # parse "def x; self::A ||= 1; end"
  
  # # ERROR in: test_const_op_asgn
  # parse "def x; ::A ||= 1; end"
  
  # test_args_assocs_comma
  parse "foo[:baz => 1,]" do
    [:call,
     [:call, nil, :foo, [:arglist]],
     :[],
     [:arglist, [:hash, [:lit, :baz], [:lit, 1]]]]
  end
  
  # test_for
  parse "for a in foo do p a; end" do
    [:for,
     [:args, [:lasgn, :a]],
     [:call, nil, :foo, [:arglist]],
     [:call, nil, :p, [:arglist, [:lvar, :a]]]]
  end
  
  # test_for
  parse "for a in foo; p a; end" do
    [:for,
     [:args, [:lasgn, :a]],
     [:call, nil, :foo, [:arglist]],
     [:call, nil, :p, [:arglist, [:lvar, :a]]]]
  end
  
  # test_ivar
  parse "@foo" do
    [:ivar, :@foo]
  end
  
  # test_args_args_assocs
  parse "fun(foo, :foo => 1)" do
    [:call,
     nil,
     :fun,
     [:arglist, [:call, nil, :foo, [:arglist]], [:hash, [:lit, :foo], [:lit, 1]]]]
  end
  
  # test_args_args_assocs
  parse "fun(foo, :foo => 1, &baz)" do
    [:call,
     nil,
     :fun,
     [:arglist,
      [:call, nil, :foo, [:arglist]],
      [:hash, [:lit, :foo], [:lit, 1]],
      [:block_pass, [:call, nil, :baz, [:arglist]]]]]
  end
  
  # test_for_mlhs
  parse "for a, b in foo; p a, b; end" do
    [:for,
     [:args, [:masgn, [:array, [:lasgn, :a], [:lasgn, :b]]]],
     [:call, nil, :foo, [:arglist]],
     [:call, nil, :p, [:arglist, [:lvar, :a], [:lvar, :b]]]]
  end
  
  # test_args_args_assocs_comma
  parse "foo[bar, :baz => 1,]" do
    [:call,
     [:call, nil, :foo, [:arglist]],
     :[],
     [:arglist, [:call, nil, :bar, [:arglist]], [:hash, [:lit, :baz], [:lit, 1]]]]
  end
  
  # test_break
  parse "break(foo)" do
    [:break, [:call, nil, :foo, [:arglist]]]
  end
  
  # test_break
  parse "break(foo)" do
    [:break, [:call, nil, :foo, [:arglist]]]
  end
  
  # test_break
  parse "break foo" do
    [:break, [:call, nil, :foo, [:arglist]]]
  end
  
  # test_break
  parse "break()" do
    [:break, [:nil]]
  end
  
  # test_break
  parse "break" do
    [:break, [:nil]]
  end
  
  # test_cvar
  parse "@@foo" do
    [:cvar, :@@foo]
  end
  
  # test_op_asgn
  parse "foo.a += 1" do
    [:op_asgn2, [:call, nil, :foo, [:arglist]], :a=, :+, [:lit, 1]]
  end
  
  # test_op_asgn
  parse "foo::a += 1" do
    [:op_asgn2, [:call, nil, :foo, [:arglist]], :a=, :+, [:lit, 1]]
  end
  
  # test_op_asgn
  parse "foo.A += 1" do
    [:op_asgn2, [:call, nil, :foo, [:arglist]], :A=, :+, [:lit, 1]]
  end
  
  # # ERROR in: test_args_args_assocs_star
  # parse "fun(foo, :foo => 1, *bar)"
  
  # # ERROR in: test_args_args_assocs_star
  # parse "fun(foo, :foo => 1, *bar, &baz)"
  
  # test_break_block
  parse "break fun foo do end" do
    [:break,
     [:call,
      nil,
      :fun,
      [:arglist, [:call, nil, :foo, [:arglist]], [:iter, [:args], [:nil]]]]]
  end
  
  # test_op_asgn_cmd
  parse "foo.a += m foo" do
    [:op_asgn2,
     [:call, nil, :foo, [:arglist]],
     :a=,
     :+,
     [:call, nil, :m, [:arglist, [:call, nil, :foo, [:arglist]]]]]
  end
  
  # test_op_asgn_cmd
  parse "foo::a += m foo" do
    [:op_asgn2,
     [:call, nil, :foo, [:arglist]],
     :a=,
     :+,
     [:call, nil, :m, [:arglist, [:call, nil, :foo, [:arglist]]]]]
  end
  
  # test_op_asgn_cmd
  parse "foo.A += m foo" do
    [:op_asgn2,
     [:call, nil, :foo, [:arglist]],
     :A=,
     :+,
     [:call, nil, :m, [:arglist, [:call, nil, :foo, [:arglist]]]]]
  end
  
  # # ERROR in: test_op_asgn_cmd
  # parse "foo::A += m foo"
  
  # test_block_kwarg_combinations
  parse "f{ |foo: 1, bar: 2, **baz, &b| }" do
    [:call,
     nil,
     :f,
     [:arglist,
      [:iter,
       [:args,
        :foo,
        :bar,
        :"**baz",
        :"&b",
        [:kwargs,
         [:foo, :bar, :"**baz"],
         [[:lasgn, :foo, [:lit, 1]], [:lasgn, :bar, [:lit, 2]]]]],
       [:nil]]]]
  end
  
  # test_block_kwarg_combinations
  parse "f{ |foo: 1, &b| }" do
    [:call,
     nil,
     :f,
     [:arglist,
      [:iter,
       [:args, :foo, :"&b", [:kwargs, [:foo], [[:lasgn, :foo, [:lit, 1]]]]],
       [:nil]]]]
  end
  
  # test_block_kwarg_combinations
  parse "f{ |**baz, &b| }" do
    [:call,
     nil,
     :f,
     [:arglist, [:iter, [:args, :"**baz", :"&b", [:kwargs, [:"**baz"]]], [:nil]]]]
  end
  
  # test_space_args_cmd
  parse "fun (f bar)" do
    [:call,
     nil,
     :fun,
     [:arglist, [:call, nil, :f, [:arglist, [:call, nil, :bar, [:arglist]]]]]]
  end
  
  # test_return
  parse "return(foo)" do
    [:return, [:call, nil, :foo, [:arglist]]]
  end
  
  # test_return
  parse "return(foo)" do
    [:return, [:call, nil, :foo, [:arglist]]]
  end
  
  # test_return
  parse "return foo" do
    [:return, [:call, nil, :foo, [:arglist]]]
  end
  
  # test_return
  parse "return()" do
    [:return, [:nil]]
  end
  
  # test_return
  parse "return" do
    [:return]
  end
  
  # test_gvar
  parse "$foo" do
    [:gvar, :$foo]
  end
  
  # test_op_asgn_index
  parse "foo[0, 1] += 2" do
    [:op_asgn1,
     [:call, nil, :foo, [:arglist]],
     [:arglist, [:lit, 0], [:lit, 1]],
     :+,
     [:lit, 2]]
  end
  
  # test_block_kwarg
  parse "f{ |foo:| }" do
    [:call, nil, :f, [:arglist, [:iter, [:args, :foo, [:kwargs, [:foo]]], [:nil]]]]
  end
  
  # test_space_args_arg
  parse "fun (1)" do
    [:call, nil, :fun, [:arglist, [:lit, 1]]]
  end
  
  # test_return_block
  parse "return fun foo do end" do
    [:return,
     [:call,
      nil,
      :fun,
      [:arglist, [:call, nil, :foo, [:arglist]], [:iter, [:args], [:nil]]]]]
  end
  
  # test_empty_stmt
  parse "" do
    [:nil]
  end
  
  # test_op_asgn_index_cmd
  parse "foo[0, 1] += m foo" do
    [:op_asgn1,
     [:call, nil, :foo, [:arglist]],
     [:arglist, [:lit, 0], [:lit, 1]],
     :+,
     [:call, nil, :m, [:arglist, [:call, nil, :foo, [:arglist]]]]]
  end
  
  # test_space_args_arg_block
  parse "fun (1) {}" do
    [:call, nil, :fun, [:arglist, [:lit, 1], [:iter, [:args], [:nil]]]]
  end
  
  # test_space_args_arg_block
  parse "foo.fun (1) {}" do
    [:call,
     [:call, nil, :foo, [:arglist]],
     :fun,
     [:arglist, [:lit, 1], [:iter, [:args], [:nil]]]]
  end
  
  # test_space_args_arg_block
  parse "foo.fun (1) {}" do
    [:call,
     [:call, nil, :foo, [:arglist]],
     :fun,
     [:arglist, [:lit, 1], [:iter, [:args], [:nil]]]]
  end
  
  # test_space_args_arg_block
  parse "foo::fun (1) {}" do
    [:call,
     [:call, nil, :foo, [:arglist]],
     :fun,
     [:arglist, [:lit, 1], [:iter, [:args], [:nil]]]]
  end
  
  # test_space_args_arg_block
  parse "foo::fun (1) {}" do
    [:call,
     [:call, nil, :foo, [:arglist]],
     :fun,
     [:arglist, [:lit, 1], [:iter, [:args], [:nil]]]]
  end
  
  # test_next
  parse "next(foo)" do
    [:next, [:call, nil, :foo, [:arglist]]]
  end
  
  # test_next
  parse "next(foo)" do
    [:next, [:call, nil, :foo, [:arglist]]]
  end
  
  # test_next
  parse "next foo" do
    [:next, [:call, nil, :foo, [:arglist]]]
  end
  
  # test_next
  parse "next()" do
    [:next, [:nil]]
  end
  
  # test_next
  parse "next" do
    [:next]
  end
  
  # test_nil
  parse "nil" do
    [:nil]
  end
  
  # test_space_args_arg_call
  parse "fun (1).to_i" do
    [:call, nil, :fun, [:arglist, [:call, [:lit, 1], :to_i, [:arglist]]]]
  end
  
  # test_next_block
  parse "next fun foo do end" do
    [:next,
     [:call,
      nil,
      :fun,
      [:arglist, [:call, nil, :foo, [:arglist]], [:iter, [:args], [:nil]]]]]
  end
  
  # test_nil_expression
  parse "()" do
    [:nil]
  end
  
  # test_nil_expression
  parse "begin end" do
    [:nil]
  end
  
  # test_var_or_asgn
  parse "a ||= 1" do
    [:op_asgn_or, [:lvar, :a], [:lasgn, :a, [:lit, 1]]]
  end
  
  # # ERROR in: test_space_args_block_pass
  # parse "fun (&foo)"
  
  # test_redo
  parse "redo" do
    [:redo]
  end
  
  # test_var_and_asgn
  parse "a &&= 1" do
    [:op_asgn_and, [:lvar, :a], [:lasgn, :a, [:lit, 1]]]
  end
  
  # # ERROR in: test_space_args_arg_block_pass
  # parse "fun (foo, &bar)"
  
  # test_rescue
  parse "begin; meth; rescue; foo; end" do
    [:rescue,
     [:block, [:nil], [:call, nil, :meth, [:arglist]]],
     [:resbody,
      [:array, [:const, :StandardError]],
      [:call, nil, :foo, [:arglist]]]]
  end
  
  # test_true
  parse "true" do
    [:true]
  end
  
  # test_back_ref
  parse "$+" do
    [:back_ref, :+]
  end
  
  # # ERROR in: test_space_args_args_star
  # parse "fun (foo, *bar)"
  
  # # ERROR in: test_space_args_args_star
  # parse "fun (foo, *bar, &baz)"
  
  # # ERROR in: test_space_args_args_star
  # parse "fun (foo, 1, *bar)"
  
  # # ERROR in: test_space_args_args_star
  # parse "fun (foo, 1, *bar, &baz)"
  
  # test_rescue_else
  parse "begin; meth; rescue; foo; else; bar; end" do
    [:rescue,
     [:block, [:nil], [:call, nil, :meth, [:arglist]]],
     [:resbody,
      [:array, [:const, :StandardError]],
      [:call, nil, :foo, [:arglist]]],
     [:block, [:nil], [:call, nil, :bar, [:arglist]]]]
  end
  
  # test_false
  parse "false" do
    [:false]
  end
  
  # test_or_asgn
  parse "foo.a ||= 1" do
    [:op_asgn2, [:call, nil, :foo, [:arglist]], :a=, :"||", [:lit, 1]]
  end
  
  # test_or_asgn
  parse "foo[0, 1] ||= 2" do
    [:op_asgn1,
     [:call, nil, :foo, [:arglist]],
     [:arglist, [:lit, 0], [:lit, 1]],
     :"||",
     [:lit, 2]]
  end
  
  # # ERROR in: test_space_args_star
  # parse "fun (*bar)"
  
  # # ERROR in: test_space_args_star
  # parse "fun (*bar, &baz)"
  
  # test_int
  parse "42" do
    [:lit, 42]
  end
  
  # test_int
  parse "-42" do
    [:lit, -42]
  end
  
  # test_nth_ref
  parse "$10" do
    [:nth_ref, 10]
  end
  
  # test_and_asgn
  parse "foo.a &&= 1" do
    [:op_asgn2, [:call, nil, :foo, [:arglist]], :a=, :"&&", [:lit, 1]]
  end
  
  # test_and_asgn
  parse "foo[0, 1] &&= 2" do
    [:op_asgn1,
     [:call, nil, :foo, [:arglist]],
     [:arglist, [:lit, 0], [:lit, 1]],
     :"&&",
     [:lit, 2]]
  end
  
  # # ERROR in: test_space_args_assocs
  # parse "fun (:foo => 1)"
  
  # # ERROR in: test_space_args_assocs
  # parse "fun (:foo => 1, &baz)"
  
  # test_int___LINE__
  parse "__LINE__" do
    [:lit, 1]
  end
  
  # test_const_toplevel
  parse "::Foo" do
    [:colon3, :Foo]
  end
  
  # test_arg_duplicate_ignored
  parse "def foo(_, _); end" do
    [:defn, :foo, [:args, :_, :"_:1"], [:scope, [:block, [:nil]]]]
  end
  
  # # ERROR in: test_arg_duplicate_ignored
  # parse "def foo(_a, _a); end"
  
  # # ERROR in: test_space_args_assocs_star
  # parse "fun (:foo => 1, *bar)"
  
  # # ERROR in: test_space_args_assocs_star
  # parse "fun (:foo => 1, *bar, &baz)"
  
  # test_ensure
  parse "begin; meth; ensure; bar; end" do
    [:ensure,
     [:block, [:nil], [:call, nil, :meth, [:arglist]]],
     [:block, [:nil], [:call, nil, :bar, [:arglist]]]]
  end
  
  # test_bug_cmd_string_lookahead
  parse "desc \"foo\" do end" do
    [:call, nil, :desc, [:arglist, [:str, "foo"], [:iter, [:args], [:nil]]]]
  end
  
  # test_float
  parse "1.33" do
    [:lit, 1.33]
  end
  
  # test_float
  parse "-1.33" do
    [:lit, -1.33]
  end
  
  # test_module
  parse "module Foo; end" do
    [:module, :Foo, [:scope]]
  end
  
  # # ERROR in: test_space_args_args_assocs
  # parse "fun (foo, :foo => 1)"
  
  # # ERROR in: test_space_args_args_assocs
  # parse "fun (foo, :foo => 1, &baz)"
  
  # # ERROR in: test_space_args_args_assocs
  # parse "fun (foo, 1, :foo => 1)"
  
  # # ERROR in: test_space_args_args_assocs
  # parse "fun (foo, 1, :foo => 1, &baz)"
  
  # test_ensure_empty
  parse "begin ensure end" do
    [:ensure, [:nil], [:nil]]
  end
  
  # test_rational
  parse "42r" do
    [:lit, (42/1)]
  end
  
  # test_rational
  parse "42.1r" do
    [:lit, (421/10)]
  end
  
  # # ERROR in: test_arg_duplicate_proc
  # parse "proc{|a,a|}"
  
  # # ERROR in: test_space_args_args_assocs_star
  # parse "fun (foo, :foo => 1, *bar)"
  
  # # ERROR in: test_space_args_args_assocs_star
  # parse "fun (foo, :foo => 1, *bar, &baz)"
  
  # # ERROR in: test_space_args_args_assocs_star
  # parse "fun (foo, 1, :foo => 1, *bar)"
  
  # # ERROR in: test_space_args_args_assocs_star
  # parse "fun (foo, 1, :foo => 1, *bar, &baz)"
  
  # test_rescue_ensure
  parse "begin; meth; rescue; baz; ensure; bar; end" do
    [:ensure,
     [:rescue,
      [:block, [:nil], [:call, nil, :meth, [:arglist]]],
      [:resbody,
       [:array, [:const, :StandardError]],
       [:call, nil, :baz, [:arglist]]]],
     [:block, [:nil], [:call, nil, :bar, [:arglist]]]]
  end
  
  # # ERROR in: test_bug_do_block_in_call_args
  # parse "bar def foo; self.each do end end"
  
  # test_const_scoped
  parse "Bar::Foo" do
    [:colon2, [:const, :Bar], :Foo]
  end
  
  # # ERROR in: test_space_args_arg_arg
  # parse "fun (1, 2)"
  
  # test_rescue_else_ensure
  parse "begin; meth; rescue; baz; else foo; ensure; bar end" do
    [:ensure,
     [:rescue,
      [:block, [:nil], [:call, nil, :meth, [:arglist]]],
      [:resbody,
       [:array, [:const, :StandardError]],
       [:call, nil, :baz, [:arglist]]],
      [:call, nil, :foo, [:arglist]]],
     [:block, [:nil], [:call, nil, :bar, [:arglist]]]]
  end
  
  # # ERROR in: test_bug_do_block_in_cmdarg
  # parse "tap (proc do end)"
  
  # test_complex
  parse "42i" do
    [:lit, (0+42i)]
  end
  
  # test_complex
  parse "42ri" do
    [:lit, (0+42/1i)]
  end
  
  # test_complex
  parse "42.1i" do
    [:lit, (0+42.1i)]
  end
  
  # test_complex
  parse "42.1ri" do
    [:lit, (0+421/10i)]
  end
  
  # test_cpath
  parse "module ::Foo; end" do
    [:module, [:colon3, :Foo], [:scope]]
  end
  
  # test_cpath
  parse "module Bar::Foo; end" do
    [:module, [:colon2, [:const, :Bar], :Foo], [:scope]]
  end
  
  # test_arg_label
  parse "def foo() a:b end" do
    [:defn,
     :foo,
     [:args],
     [:scope, [:block, [:call, nil, :a, [:arglist, [:lit, :b]]]]]]
  end
  
  # test_arg_label
  parse "def foo\n a:b end" do
    [:defn,
     :foo,
     [:args],
     [:scope, [:block, [:call, nil, :a, [:arglist, [:lit, :b]]]]]]
  end
  
  # test_arg_label
  parse "f { || a:b }" do
    [:call,
     nil,
     :f,
     [:arglist, [:iter, [:args], [:call, nil, :a, [:arglist, [:lit, :b]]]]]]
  end
  
  # test_space_args_none
  parse "fun ()" do
    [:call, nil, :fun, [:arglist, [:nil]]]
  end
  
  # test_rescue_mod
  parse "meth rescue bar" do
    [:rescue,
     [:call, nil, :meth, [:arglist]],
     [:resbody,
      [:array, [:const, :StandardError]],
      [:call, nil, :bar, [:arglist]]]]
  end
  
  # test_bug_interp_single
  parse "\"\#{1}\"" do
    [:dstr, "", [:evstr, [:lit, 1]]]
  end
  
  # test_bug_interp_single
  parse "%W\"\#{1}\"" do
    [:array, [:dstr, "", [:evstr, [:lit, 1]]]]
  end
  
  # test_const_unscoped
  parse "Foo" do
    [:const, :Foo]
  end
  
  # test_send_self
  parse "fun" do
    [:call, nil, :fun, [:arglist]]
  end
  
  # test_send_self
  parse "fun!" do
    [:call, nil, :fun!, [:arglist]]
  end
  
  # test_send_self
  parse "fun(1)" do
    [:call, nil, :fun, [:arglist, [:lit, 1]]]
  end
  
  # test_space_args_block
  parse "fun () {}" do
    [:call, nil, :fun, [:arglist, [:nil], [:iter, [:args], [:nil]]]]
  end
  
  # test_space_args_block
  parse "foo.fun () {}" do
    [:call,
     [:call, nil, :foo, [:arglist]],
     :fun,
     [:arglist, [:nil], [:iter, [:args], [:nil]]]]
  end
  
  # test_space_args_block
  parse "foo::fun () {}" do
    [:call,
     [:call, nil, :foo, [:arglist]],
     :fun,
     [:arglist, [:nil], [:iter, [:args], [:nil]]]]
  end
  
  # test_space_args_block
  parse "fun () {}" do
    [:call, nil, :fun, [:arglist, [:nil], [:iter, [:args], [:nil]]]]
  end
  
  # test_rescue_mod_asgn
  parse "foo = meth rescue bar" do
    [:lasgn,
     :foo,
     [:rescue,
      [:call, nil, :meth, [:arglist]],
      [:resbody,
       [:array, [:const, :StandardError]],
       [:call, nil, :bar, [:arglist]]]]]
  end
  
  # test_bug_def_no_paren_eql_begin
  parse "def foo\n=begin\n=end\nend" do
    [:defn, :foo, [:args], [:scope, [:block, [:nil]]]]
  end
  
  # test_string_plain
  parse "'foobar'" do
    [:str, "foobar"]
  end
  
  # test_string_plain
  parse "%q(foobar)" do
    [:str, "foobar"]
  end
  
  # test___ENCODING__
  parse "__ENCODING__" do
    [:encoding, "UTF-8"]
  end
  
  # test_and
  parse "foo and bar" do
    [:and, [:call, nil, :foo, [:arglist]], [:call, nil, :bar, [:arglist]]]
  end
  
  # test_and
  parse "foo && bar" do
    [:and, [:call, nil, :foo, [:arglist]], [:call, nil, :bar, [:arglist]]]
  end
  
  # test_rescue_mod_op_assign
  parse "foo += meth rescue bar" do
    [:lasgn,
     :foo,
     [:call,
      [:lvar, :foo],
      :+,
      [:arglist,
       [:rescue,
        [:call, nil, :meth, [:arglist]],
        [:resbody,
         [:array, [:const, :StandardError]],
         [:call, nil, :bar, [:arglist]]]]]]]
  end
  
  # test_bug_while_not_parens_do
  parse "while not (true) do end" do
    [:while, [:call, [:true], :!, [:arglist]], [:nil], true]
  end
  
  # test_string_interp
  parse "\"foo\#{bar}baz\"" do
    [:dstr, "foo", [:evstr, [:call, nil, :bar, [:arglist]]], [:str, "baz"]]
  end
  
  # test_defined
  parse "defined? foo" do
    [:defined, [:call, nil, :foo, [:arglist]]]
  end
  
  # test_defined
  parse "defined?(foo)" do
    [:defined, [:call, nil, :foo, [:arglist]]]
  end
  
  # test_defined
  parse "defined? @foo" do
    [:defined, [:ivar, :@foo]]
  end
  
  # test_class
  parse "class Foo; end" do
    [:class, :Foo, nil, [:scope]]
  end
  
  # test_or
  parse "foo or bar" do
    [:or, [:call, nil, :foo, [:arglist]], [:call, nil, :bar, [:arglist]]]
  end
  
  # test_or
  parse "foo || bar" do
    [:or, [:call, nil, :foo, [:arglist]], [:call, nil, :bar, [:arglist]]]
  end
  
  # test_resbody_list
  parse "begin; meth; rescue Exception; bar; end" do
    [:rescue,
     [:block, [:nil], [:call, nil, :meth, [:arglist]]],
     [:resbody, [:array, [:const, :Exception]], [:call, nil, :bar, [:arglist]]]]
  end
  
  # test_bug_rescue_empty_else
  parse "begin; rescue LoadError; else; end" do
    [:rescue, [:nil], [:resbody, [:array, [:const, :LoadError]], [:nil]], [:nil]]
  end
  
  # test_class_super
  parse "class Foo < Bar; end" do
    [:class, :Foo, [:const, :Bar], [:scope]]
  end
  
  # test_send_self_block
  parse "fun { }" do
    [:call, nil, :fun, [:arglist, [:iter, [:args], [:nil]]]]
  end
  
  # test_send_self_block
  parse "fun() { }" do
    [:call, nil, :fun, [:arglist, [:iter, [:args], [:nil]]]]
  end
  
  # test_send_self_block
  parse "fun(1) { }" do
    [:call, nil, :fun, [:arglist, [:lit, 1], [:iter, [:args], [:nil]]]]
  end
  
  # test_send_self_block
  parse "fun do end" do
    [:call, nil, :fun, [:arglist, [:iter, [:args], [:nil]]]]
  end
  
  # test_and_or_masgn
  parse "foo && (a, b = bar)" do
    [:and,
     [:call, nil, :foo, [:arglist]],
     [:masgn,
      [:array, [:lasgn, :a], [:lasgn, :b]],
      [:call, nil, :bar, [:arglist]]]]
  end
  
  # test_and_or_masgn
  parse "foo || (a, b = bar)" do
    [:or,
     [:call, nil, :foo, [:arglist]],
     [:masgn,
      [:array, [:lasgn, :a], [:lasgn, :b]],
      [:call, nil, :bar, [:arglist]]]]
  end
  
  # test_resbody_list_mrhs
  parse "begin; meth; rescue Exception, foo; bar; end" do
    [:rescue,
     [:block, [:nil], [:call, nil, :meth, [:arglist]]],
     [:resbody,
      [:array, [:const, :Exception], [:call, nil, :foo, [:arglist]]],
      [:call, nil, :bar, [:arglist]]]]
  end
  
  # test_bug_heredoc_do
  parse "f <<-TABLE do\nTABLE\nend" do
    [:call, nil, :f, [:arglist, [:str, ""], [:iter, [:args], [:nil]]]]
  end
  
  # test_string_dvar
  parse "\"\#@a \#@@a \#$a\"" do
    [:dstr,
     "",
     [:evstr, [:ivar, :@a]],
     [:str, " "],
     [:evstr, [:cvar, :@@a]],
     [:str, " "],
     [:evstr, [:gvar, :$a]]]
  end
  
  # test_lvasgn
  parse "var = 10; var" do
    [:block, [:lasgn, :var, [:lit, 10]], [:lvar, :var]]
  end
  
  # test_class_super_label
  parse "class Foo < a:b; end" do
    [:class, :Foo, [:call, nil, :a, [:arglist, [:lit, :b]]], [:scope]]
  end
  
  # test_if
  parse "if foo then bar; end" do
    [:if, [:call, nil, :foo, [:arglist]], [:call, nil, :bar, [:arglist]], nil]
  end
  
  # test_if
  parse "if foo; bar; end" do
    [:if, [:call, nil, :foo, [:arglist]], [:call, nil, :bar, [:arglist]], nil]
  end
  
  # test_resbody_var
  parse "begin; meth; rescue => ex; bar; end" do
    [:rescue,
     [:block, [:nil], [:call, nil, :meth, [:arglist]]],
     [:resbody,
      [:array, [:const, :StandardError], [:lasgn, :ex, [:gvar, :$!]]],
      [:call, nil, :bar, [:arglist]]]]
  end
  
  # test_resbody_var
  parse "begin; meth; rescue => @ex; bar; end" do
    [:rescue,
     [:block, [:nil], [:call, nil, :meth, [:arglist]]],
     [:resbody,
      [:array, [:const, :StandardError], [:iasgn, :@ex, [:gvar, :$!]]],
      [:call, nil, :bar, [:arglist]]]]
  end
  
  # # ERROR in: test_ruby_bug_9669
  # parse "def a b:\nreturn\nend"
  
  # test_ruby_bug_9669
  parse "o = {\na:\n1\n}" do
    [:lasgn, :o, [:hash, [:lit, :a], [:lit, 1]]]
  end
  
  # test_if_nl_then
  parse "if foo\nthen bar end" do
    [:if, [:call, nil, :foo, [:arglist]], [:call, nil, :bar, [:arglist]], nil]
  end
  
  # test_ruby_bug_10279
  parse "{a: if true then 42 end}" do
    [:hash, [:lit, :a], [:if, [:true], [:lit, 42], nil]]
  end
  
  # test_ivasgn
  parse "@var = 10" do
    [:iasgn, :@var, [:lit, 10]]
  end
  
  # test_send_plain
  parse "foo.fun" do
    [:call, [:call, nil, :foo, [:arglist]], :fun, [:arglist]]
  end
  
  # test_send_plain
  parse "foo::fun" do
    [:call, [:call, nil, :foo, [:arglist]], :fun, [:arglist]]
  end
  
  # test_send_plain
  parse "foo::Fun()" do
    [:call, [:call, nil, :foo, [:arglist]], :Fun, [:arglist]]
  end
  
  # test_if_mod
  parse "bar if foo" do
    [:if, [:call, nil, :foo, [:arglist]], [:call, nil, :bar, [:arglist]], nil]
  end
  
  # test_resbody_list_var
  parse "begin; meth; rescue foo => ex; bar; end" do
    [:rescue,
     [:block, [:nil], [:call, nil, :meth, [:arglist]]],
     [:resbody,
      [:array, [:call, nil, :foo, [:arglist]], [:lasgn, :ex, [:gvar, :$!]]],
      [:call, nil, :bar, [:arglist]]]]
  end
  
  # test_bug_lambda_leakage
  parse "->(scope) {}; scope" do
    [:block,
     [:lambda, [:args, :scope], [:scope, [:nil]]],
     [:call, nil, :scope, [:arglist]]]
  end
  
  # test_sclass
  parse "class << foo; nil; end" do
    [:sclass, [:call, nil, :foo, [:arglist]], [:scope, [:block, [:nil]]]]
  end
  
  # test_unless
  parse "unless foo then bar; end" do
    [:if, [:call, nil, :foo, [:arglist]], [:nil], [:call, nil, :bar, [:arglist]]]
  end
  
  # test_unless
  parse "unless foo; bar; end" do
    [:if, [:call, nil, :foo, [:arglist]], [:nil], [:call, nil, :bar, [:arglist]]]
  end
  
  # test_retry
  parse "retry" do
    [:retry]
  end
  
  # test_string_concat
  parse "\"foo\#@a\" \"bar\"" do
    [:dstr, "foo", [:evstr, [:ivar, :@a]], [:str, "bar"]]
  end
  
  # test_def
  parse "def foo; end" do
    [:defn, :foo, [:args], [:scope, [:block, [:nil]]]]
  end
  
  # test_def
  parse "def String; end" do
    [:defn, :String, [:args], [:scope, [:block, [:nil]]]]
  end
  
  # test_def
  parse "def String=; end" do
    [:defn, :String=, [:args], [:scope, [:block, [:nil]]]]
  end
  
  # test_def
  parse "def until; end" do
    [:defn, :until, [:args], [:scope, [:block, [:nil]]]]
  end
  
  # test_send_plain_cmd
  parse "foo.fun bar" do
    [:call,
     [:call, nil, :foo, [:arglist]],
     :fun,
     [:arglist, [:call, nil, :bar, [:arglist]]]]
  end
  
  # test_send_plain_cmd
  parse "foo::fun bar" do
    [:call,
     [:call, nil, :foo, [:arglist]],
     :fun,
     [:arglist, [:call, nil, :bar, [:arglist]]]]
  end
  
  # test_send_plain_cmd
  parse "foo::Fun bar" do
    [:call,
     [:call, nil, :foo, [:arglist]],
     :Fun,
     [:arglist, [:call, nil, :bar, [:arglist]]]]
  end
  
  # test_unless_mod
  parse "bar unless foo" do
    [:if, [:call, nil, :foo, [:arglist]], [:nil], [:call, nil, :bar, [:arglist]]]
  end
  
  # test_preexe
  parse "BEGIN { 1 }" do
    nil
  end
  
  # test_string___FILE__
  parse "__FILE__" do
    [:file]
  end
  
  # test_cvasgn
  parse "@@var = 10" do
    [:cvasgn, :@@var, [:lit, 10]]
  end
  
  # test_if_else
  parse "if foo then bar; else baz; end" do
    [:if,
     [:call, nil, :foo, [:arglist]],
     [:call, nil, :bar, [:arglist]],
     [:call, nil, :baz, [:arglist]]]
  end
  
  # test_if_else
  parse "if foo; bar; else baz; end" do
    [:if,
     [:call, nil, :foo, [:arglist]],
     [:call, nil, :bar, [:arglist]],
     [:call, nil, :baz, [:arglist]]]
  end
  
  # test_character
  parse "?a" do
    [:str, "a"]
  end
  
  # test_character
  parse "?a" do
    [:str, "a"]
  end
  
  # test_defs
  parse "def self.foo; end" do
    [:defs, [:self], :foo, [:args], [:scope, [:block, [:nil]]]]
  end
  
  # test_defs
  parse "def self::foo; end" do
    [:defs, [:self], :foo, [:args], [:scope, [:block, [:nil]]]]
  end
  
  # test_defs
  parse "def (foo).foo; end" do
    [:defs,
     [:call, nil, :foo, [:arglist]],
     :foo,
     [:args],
     [:scope, [:block, [:nil]]]]
  end
  
  # test_defs
  parse "def String.foo; end" do
    [:defs, [:const, :String], :foo, [:args], [:scope, [:block, [:nil]]]]
  end
  
  # test_defs
  parse "def String::foo; end" do
    [:defs, [:const, :String], :foo, [:args], [:scope, [:block, [:nil]]]]
  end
  
  # test_unless_else
  parse "unless foo then bar; else baz; end" do
    [:if,
     [:call, nil, :foo, [:arglist]],
     [:call, nil, :baz, [:arglist]],
     [:call, nil, :bar, [:arglist]]]
  end
  
  # test_unless_else
  parse "unless foo; bar; else baz; end" do
    [:if,
     [:call, nil, :foo, [:arglist]],
     [:call, nil, :baz, [:arglist]],
     [:call, nil, :bar, [:arglist]]]
  end
  
  # test_heredoc
  parse "<<HERE\nfoo\nbar\nHERE" do
    [:str, "foo\nbar\n"]
  end
  
  # test_heredoc
  parse "<<'HERE'\nfoo\nbar\nHERE" do
    [:str, "foo\nbar\n"]
  end
  
  # test_heredoc
  parse "<<`HERE`\nfoo\nbar\nHERE" do
    [:xstr, "foo\nbar\n"]
  end
  
  # test_gvasgn
  parse "$var = 10" do
    [:gasgn, :$var, [:lit, 10]]
  end
  
  # test_if_elsif
  parse "if foo; bar; elsif baz; 1; else 2; end" do
    [:if,
     [:call, nil, :foo, [:arglist]],
     [:call, nil, :bar, [:arglist]],
     [:if, [:call, nil, :baz, [:arglist]], [:lit, 1], [:lit, 2]]]
  end
  
  # test_symbol_plain
  parse ":foo" do
    [:lit, :foo]
  end
  
  # test_symbol_plain
  parse ":'foo'" do
    [:lit, :foo]
  end
  
  # test_ternary
  parse "foo ? 1 : 2" do
    [:if, [:call, nil, :foo, [:arglist]], [:lit, 1], [:lit, 2]]
  end
  
  # test_postexe
  parse "END { 1 }" do
    [:call, nil, :at_exit, [:arglist, [:iter, [:args], [:block, [:lit, 1]]]]]
  end
  
  # test_undef
  parse "undef foo, :bar, :\"foo\#{1}\"" do
    [:block,
     [:undef, [:lit, :foo]],
     [:undef, [:lit, :bar]],
     [:undef, [:dsym, "foo", [:evstr, [:lit, 1]]]]]
  end
  
  # test_send_block_chain_cmd
  parse "meth 1 do end.fun bar" do
    [:call,
     [:call, nil, :meth, [:arglist, [:lit, 1], [:iter, [:args], [:nil]]]],
     :fun,
     [:arglist, [:call, nil, :bar, [:arglist]]]]
  end
  
  # test_send_block_chain_cmd
  parse "meth 1 do end.fun(bar)" do
    [:call,
     [:call, nil, :meth, [:arglist, [:lit, 1], [:iter, [:args], [:nil]]]],
     :fun,
     [:arglist, [:call, nil, :bar, [:arglist]]]]
  end
  
  # test_send_block_chain_cmd
  parse "meth 1 do end::fun bar" do
    [:call,
     [:call, nil, :meth, [:arglist, [:lit, 1], [:iter, [:args], [:nil]]]],
     :fun,
     [:arglist, [:call, nil, :bar, [:arglist]]]]
  end
  
  # test_send_block_chain_cmd
  parse "meth 1 do end::fun(bar)" do
    [:call,
     [:call, nil, :meth, [:arglist, [:lit, 1], [:iter, [:args], [:nil]]]],
     :fun,
     [:arglist, [:call, nil, :bar, [:arglist]]]]
  end
  
  # test_send_block_chain_cmd
  parse "meth 1 do end.fun bar do end" do
    [:call,
     [:call, nil, :meth, [:arglist, [:lit, 1], [:iter, [:args], [:nil]]]],
     :fun,
     [:arglist, [:call, nil, :bar, [:arglist]], [:iter, [:args], [:nil]]]]
  end
  
  # test_send_block_chain_cmd
  parse "meth 1 do end.fun(bar) {}" do
    [:call,
     [:call, nil, :meth, [:arglist, [:lit, 1], [:iter, [:args], [:nil]]]],
     :fun,
     [:arglist, [:call, nil, :bar, [:arglist]], [:iter, [:args], [:nil]]]]
  end
  
  # test_send_block_chain_cmd
  parse "meth 1 do end.fun {}" do
    [:call,
     [:call, nil, :meth, [:arglist, [:lit, 1], [:iter, [:args], [:nil]]]],
     :fun,
     [:arglist, [:iter, [:args], [:nil]]]]
  end
  
  # test_ternary_ambiguous_symbol
  parse "t=1;(foo)?t:T" do
    [:block,
     [:lasgn, :t, [:lit, 1]],
     [:if, [:call, nil, :foo, [:arglist]], [:lvar, :t], [:const, :T]]]
  end
  
  # test_symbol_interp
  parse ":\"foo\#{bar}baz\"" do
    [:dsym, "foo", [:evstr, [:call, nil, :bar, [:arglist]]], [:str, "baz"]]
  end
  
  # test_asgn_cmd
  parse "foo = m foo" do
    [:lasgn, :foo, [:call, nil, :m, [:arglist, [:lvar, :foo]]]]
  end
  
  # test_asgn_cmd
  parse "foo = bar = m foo" do
    [:lasgn, :foo, [:lasgn, :bar, [:call, nil, :m, [:arglist, [:lvar, :foo]]]]]
  end
  
  # test_alias
  parse "alias :foo bar" do
    [:alias, [:lit, :foo], [:lit, :bar]]
  end
  
  # # ERROR in: test_send_paren_block_cmd
  # parse "foo(meth 1 do end)"
  
  # # ERROR in: test_send_paren_block_cmd
  # parse "foo(1, meth 1 do end)"
  
  # test_kwbegin_compstmt
  parse "begin foo!; bar! end" do
    [:block, [:call, nil, :foo!, [:arglist]], [:call, nil, :bar!, [:arglist]]]
  end
  
  # test_alias_gvar
  parse "alias $a $b" do
    [:valias, :$a, :$b]
  end
  
  # test_alias_gvar
  parse "alias $a $+" do
    [:valias, :$a, :$+]
  end
  
  # test_send_binary_op
  parse "foo + 1" do
    [:call, [:call, nil, :foo, [:arglist]], :+, [:arglist, [:lit, 1]]]
  end
  
  # test_send_binary_op
  parse "foo - 1" do
    [:call, [:call, nil, :foo, [:arglist]], :-, [:arglist, [:lit, 1]]]
  end
  
  # test_send_binary_op
  parse "foo * 1" do
    [:call, [:call, nil, :foo, [:arglist]], :*, [:arglist, [:lit, 1]]]
  end
  
  # test_send_binary_op
  parse "foo / 1" do
    [:call, [:call, nil, :foo, [:arglist]], :/, [:arglist, [:lit, 1]]]
  end
  
  # test_send_binary_op
  parse "foo % 1" do
    [:call, [:call, nil, :foo, [:arglist]], :%, [:arglist, [:lit, 1]]]
  end
  
  # test_send_binary_op
  parse "foo ** 1" do
    [:call, [:call, nil, :foo, [:arglist]], :**, [:arglist, [:lit, 1]]]
  end
  
  # test_send_binary_op
  parse "foo | 1" do
    [:call, [:call, nil, :foo, [:arglist]], :|, [:arglist, [:lit, 1]]]
  end
  
  # test_send_binary_op
  parse "foo ^ 1" do
    [:call, [:call, nil, :foo, [:arglist]], :^, [:arglist, [:lit, 1]]]
  end
  
  # test_send_binary_op
  parse "foo & 1" do
    [:call, [:call, nil, :foo, [:arglist]], :&, [:arglist, [:lit, 1]]]
  end
  
  # test_send_binary_op
  parse "foo <=> 1" do
    [:call, [:call, nil, :foo, [:arglist]], :<=>, [:arglist, [:lit, 1]]]
  end
  
  # test_send_binary_op
  parse "foo < 1" do
    [:call, [:call, nil, :foo, [:arglist]], :<, [:arglist, [:lit, 1]]]
  end
  
  # test_send_binary_op
  parse "foo <= 1" do
    [:call, [:call, nil, :foo, [:arglist]], :<=, [:arglist, [:lit, 1]]]
  end
  
  # test_send_binary_op
  parse "foo > 1" do
    [:call, [:call, nil, :foo, [:arglist]], :>, [:arglist, [:lit, 1]]]
  end
  
  # test_send_binary_op
  parse "foo >= 1" do
    [:call, [:call, nil, :foo, [:arglist]], :>=, [:arglist, [:lit, 1]]]
  end
  
  # test_send_binary_op
  parse "foo == 1" do
    [:call, [:call, nil, :foo, [:arglist]], :==, [:arglist, [:lit, 1]]]
  end
  
  # test_send_binary_op
  parse "foo != 1" do
    [:call, [:call, nil, :foo, [:arglist]], :!=, [:arglist, [:lit, 1]]]
  end
  
  # test_send_binary_op
  parse "foo != 1" do
    [:call, [:call, nil, :foo, [:arglist]], :!=, [:arglist, [:lit, 1]]]
  end
  
  # test_send_binary_op
  parse "foo === 1" do
    [:call, [:call, nil, :foo, [:arglist]], :===, [:arglist, [:lit, 1]]]
  end
  
  # test_send_binary_op
  parse "foo =~ 1" do
    [:call, [:call, nil, :foo, [:arglist]], :=~, [:arglist, [:lit, 1]]]
  end
  
  # test_send_binary_op
  parse "foo !~ 1" do
    [:call, [:call, nil, :foo, [:arglist]], :!~, [:arglist, [:lit, 1]]]
  end
  
  # test_send_binary_op
  parse "foo !~ 1" do
    [:call, [:call, nil, :foo, [:arglist]], :!~, [:arglist, [:lit, 1]]]
  end
  
  # test_send_binary_op
  parse "foo << 1" do
    [:call, [:call, nil, :foo, [:arglist]], :<<, [:arglist, [:lit, 1]]]
  end
  
  # test_send_binary_op
  parse "foo >> 1" do
    [:call, [:call, nil, :foo, [:arglist]], :>>, [:arglist, [:lit, 1]]]
  end
  
  # test_send_unary_op
  parse "-foo" do
    [:call, [:call, nil, :foo, [:arglist]], :-@, [:arglist]]
  end
  
  # test_send_unary_op
  parse "+foo" do
    [:call, [:call, nil, :foo, [:arglist]], :+@, [:arglist]]
  end
  
  # test_send_unary_op
  parse "~foo" do
    [:call, [:call, nil, :foo, [:arglist]], :~, [:arglist]]
  end
  
  # test_xstring_plain
  parse "`foobar`" do
    [:xstr, "foobar"]
  end
  
  # test_bang
  parse "!foo" do
    [:call, [:call, nil, :foo, [:arglist]], :!, [:arglist]]
  end
  
  # test_bang
  parse "!foo" do
    [:call, [:call, nil, :foo, [:arglist]], :!, [:arglist]]
  end
  
  # test_xstring_interp
  parse "`foo\#{bar}baz`" do
    [:dxstr, "foo", [:evstr, [:call, nil, :bar, [:arglist]]], [:str, "baz"]]
  end
  
  # test_bang_cmd
  parse "!m foo" do
    [:call,
     [:call, nil, :m, [:arglist, [:call, nil, :foo, [:arglist]]]],
     :!,
     [:arglist]]
  end
  
  # test_bang_cmd
  parse "!m foo" do
    [:call,
     [:call, nil, :m, [:arglist, [:call, nil, :foo, [:arglist]]]],
     :!,
     [:arglist]]
  end
  
  # test_regex_plain
  parse "/source/im" do
    [:regex, "source", 5]
  end
  
  # test_casgn_toplevel
  parse "::Foo = 10" do
    [:cdecl, [:colon3, :Foo], [:lit, 10]]
  end
  
  # test_arg
  parse "def f(foo); end" do
    [:defn, :f, [:args, :foo], [:scope, [:block, [:nil]]]]
  end
  
  # test_arg
  parse "def f(foo, bar); end" do
    [:defn, :f, [:args, :foo, :bar], [:scope, [:block, [:nil]]]]
  end
  
  # test_not
  parse "not foo" do
    [:call, [:call, nil, :foo, [:arglist]], :!, [:arglist]]
  end
  
  # test_not
  parse "not foo" do
    [:call, [:call, nil, :foo, [:arglist]], :!, [:arglist]]
  end
  
  # test_not
  parse "not(foo)" do
    [:call, [:call, nil, :foo, [:arglist]], :!, [:arglist]]
  end
  
  # test_not
  parse "not()" do
    [:call, [:nil], :!, [:arglist]]
  end
  
  # test_cond_begin
  parse "if (bar); foo; end" do
    [:if, [:call, nil, :bar, [:arglist]], [:call, nil, :foo, [:arglist]], nil]
  end
  
  # test_optarg
  parse "def f foo = 1; end" do
    [:defn,
     :f,
     [:args, :foo, [:block, [:lasgn, :foo, [:lit, 1]]]],
     [:scope, [:block, [:nil]]]]
  end
  
  # test_optarg
  parse "def f(foo=1, bar=2); end" do
    [:defn,
     :f,
     [:args,
      :foo,
      :bar,
      [:block, [:lasgn, :foo, [:lit, 1]], [:lasgn, :bar, [:lit, 2]]]],
     [:scope, [:block, [:nil]]]]
  end
  
  # test_not_cmd
  parse "not m foo" do
    [:call,
     [:call, nil, :m, [:arglist, [:call, nil, :foo, [:arglist]]]],
     :!,
     [:arglist]]
  end
  
  # test_not_cmd
  parse "not m foo" do
    [:call,
     [:call, nil, :m, [:arglist, [:call, nil, :foo, [:arglist]]]],
     :!,
     [:arglist]]
  end
  
  # test_cond_begin_masgn
  parse "if (bar; a, b = foo); end" do
    [:if,
     [:block,
      [:call, nil, :bar, [:arglist]],
      [:masgn,
       [:array, [:lasgn, :a], [:lasgn, :b]],
       [:call, nil, :foo, [:arglist]]]],
     [:nil],
     nil]
  end
  
  # test_regex_interp
  parse "/foo\#{bar}baz/" do
    [:dregx, "foo", [:evstr, [:call, nil, :bar, [:arglist]]], [:str, "baz"]]
  end
  
  # test_casgn_scoped
  parse "Bar::Foo = 10" do
    [:cdecl, [:colon2, [:const, :Bar], :Foo], [:lit, 10]]
  end
  
  # test_pow_precedence
  parse "-2 ** 10" do
    [:call, [:call, [:lit, 2], :**, [:arglist, [:lit, 10]]], :-@, [:arglist]]
  end
  
  # test_pow_precedence
  parse "-2.0 ** 10" do
    [:call, [:call, [:lit, 2.0], :**, [:arglist, [:lit, 10]]], :-@, [:arglist]]
  end
  
  # # ERROR in: test_cond_begin_and_or_masgn
  # parse "if (a, b = foo) && bar; end"
  
  # test_array_plain
  parse "[1, 2]" do
    [:array, [:lit, 1], [:lit, 2]]
  end
  
  # test_casgn_unscoped
  parse "Foo = 10" do
    [:cdecl, :Foo, [:lit, 10]]
  end
  
  # test_restarg_named
  parse "def f(*foo); end" do
    [:defn, :f, [:args, :"*foo"], [:scope, [:block, [:nil]]]]
  end
  
  # test_send_attr_asgn
  parse "foo.a = 1" do
    [:attrasgn, [:call, nil, :foo, [:arglist]], :a=, [:arglist, [:lit, 1]]]
  end
  
  # test_send_attr_asgn
  parse "foo::a = 1" do
    [:attrasgn, [:call, nil, :foo, [:arglist]], :a=, [:arglist, [:lit, 1]]]
  end
  
  # test_send_attr_asgn
  parse "foo.A = 1" do
    [:attrasgn, [:call, nil, :foo, [:arglist]], :A=, [:arglist, [:lit, 1]]]
  end
  
  # test_send_attr_asgn
  parse "foo::A = 1" do
    [:cdecl, [:colon2, [:call, nil, :foo, [:arglist]], :A], [:lit, 1]]
  end
  
  # test_cond_iflipflop
  parse "if foo..bar; end" do
    [:if,
     [:flip2, [:call, nil, :foo, [:arglist]], [:call, nil, :bar, [:arglist]]],
     [:nil],
     nil]
  end
  
  # test_begin_cmdarg
  parse "p begin 1.times do 1 end end" do
    [:call,
     nil,
     :p,
     [:arglist,
      [:call, [:lit, 1], :times, [:arglist, [:iter, [:args], [:lit, 1]]]]]]
  end
  
  # test_array_splat
  parse "[1, *foo, 2]" do
    [:argspush,
     [:argscat, [:array, [:lit, 1]], [:call, nil, :foo, [:arglist]]],
     [:lit, 2]]
  end
  
  # test_array_splat
  parse "[1, *foo]" do
    [:argscat, [:array, [:lit, 1]], [:call, nil, :foo, [:arglist]]]
  end
  
  # test_array_splat
  parse "[*foo]" do
    [:splat, [:call, nil, :foo, [:arglist]]]
  end
  
  # test_send_index
  parse "foo[1, 2]" do
    [:call, [:call, nil, :foo, [:arglist]], :[], [:arglist, [:lit, 1], [:lit, 2]]]
  end
  
  # # ERROR in: test_bug_cmdarg
  # parse "meth (lambda do end)"
  
  # test_bug_cmdarg
  parse "assert dogs" do
    [:call, nil, :assert, [:arglist, [:call, nil, :dogs, [:arglist]]]]
  end
  
  # test_bug_cmdarg
  parse "assert do: true" do
    [:call, nil, :assert, [:arglist, [:hash, [:lit, :do], [:true]]]]
  end
  
  # test_bug_cmdarg
  parse "f x: -> do meth do end end" do
    [:call,
     nil,
     :f,
     [:arglist,
      [:hash,
       [:lit, :x],
       [:lambda,
        [:args],
        [:scope, [:call, nil, :meth, [:arglist, [:iter, [:args], [:nil]]]]]]]]]
  end
  
  # test_array_assocs
  parse "[ 1 => 2 ]" do
    [:array, [:hash, [:lit, 1], [:lit, 2]]]
  end
  
  # test_array_assocs
  parse "[ 1, 2 => 3 ]" do
    [:array, [:lit, 1], [:hash, [:lit, 2], [:lit, 3]]]
  end
  
  # test_restarg_unnamed
  parse "def f(*); end" do
    [:defn, :f, [:args, :*], [:scope, [:block, [:nil]]]]
  end
  
  # test_send_index_cmd
  parse "foo[m bar]" do
    [:call,
     [:call, nil, :foo, [:arglist]],
     :[],
     [:arglist, [:call, nil, :m, [:arglist, [:call, nil, :bar, [:arglist]]]]]]
  end
  
  # test_cond_eflipflop
  parse "if foo...bar; end" do
    [:if,
     [:flip3, [:call, nil, :foo, [:arglist]], [:call, nil, :bar, [:arglist]]],
     [:nil],
     nil]
  end
  
  # test_array_words
  parse "%w[foo bar]" do
    [:array, [:str, "foo"], [:str, "bar"]]
  end
  
  # test_masgn
  parse "foo, bar = 1, 2" do
    [:masgn,
     [:array, [:lasgn, :foo], [:lasgn, :bar]],
     [:array, [:lit, 1], [:lit, 2]]]
  end
  
  # test_masgn
  parse "(foo, bar) = 1, 2" do
    [:masgn,
     [:array, [:lasgn, :foo], [:lasgn, :bar]],
     [:array, [:lit, 1], [:lit, 2]]]
  end
  
  # test_masgn
  parse "foo, bar, baz = 1, 2" do
    [:masgn,
     [:array, [:lasgn, :foo], [:lasgn, :bar], [:lasgn, :baz]],
     [:array, [:lit, 1], [:lit, 2]]]
  end
  
  # test_kwarg
  parse "def f(foo:); end" do
    [:defn, :f, [:args, :foo, [:kwargs, [:foo]]], [:scope, [:block, [:nil]]]]
  end
  
  # test_send_index_asgn
  parse "foo[1, 2] = 3" do
    [:attrasgn,
     [:call, nil, :foo, [:arglist]],
     :[]=,
     [:arglist, [:lit, 1], [:lit, 2], [:lit, 3]]]
  end
  
  # test_array_words_interp
  parse "%W[foo \#{bar}]" do
    [:array, [:str, "foo"], [:dstr, "", [:evstr, [:call, nil, :bar, [:arglist]]]]]
  end
  
  # test_array_words_interp
  parse "%W[foo \#{bar}foo\#@baz]" do
    [:array,
     [:str, "foo"],
     [:dstr,
      "",
      [:evstr, [:call, nil, :bar, [:arglist]]],
      [:str, "foo"],
      [:evstr, [:ivar, :@baz]]]]
  end
  
  # test_send_lambda
  parse "->{ }" do
    [:lambda, [:args], [:scope, [:nil]]]
  end
  
  # test_send_lambda
  parse "-> * { }" do
    [:lambda, [:args, :*], [:scope, [:nil]]]
  end
  
  # test_send_lambda
  parse "-> do end" do
    [:lambda, [:args], [:scope, [:nil]]]
  end
  
  # test_cond_match_current_line
  parse "if /wat/; end" do
    [:if, [:match, [:regex, "wat", 0]], [:nil], nil]
  end
  
  # test_kwoptarg
  parse "def f(foo: 1); end" do
    [:defn,
     :f,
     [:args, :foo, [:kwargs, [:foo], [[:lasgn, :foo, [:lit, 1]]]]],
     [:scope, [:block, [:nil]]]]
  end
  
  # test_send_lambda_args
  parse "->(a) { }" do
    [:lambda, [:args, :a], [:scope, [:nil]]]
  end
  
  # test_send_lambda_args
  parse "-> (a) { }" do
    [:lambda, [:args, :a], [:scope, [:nil]]]
  end
  
  # test_array_words_empty
  parse "%w[]" do
    [:array]
  end
  
  # test_array_words_empty
  parse "%W()" do
    [:array]
  end
  
  # test_masgn_splat
  parse "@foo, @@bar = *foo" do
    [:masgn,
     [:array, [:iasgn, :@foo], [:cvasgn, :@@bar]],
     [:splat, [:call, nil, :foo, [:arglist]]]]
  end
  
  # test_masgn_splat
  parse "a, b = *foo, bar" do
    [:masgn,
     [:array, [:lasgn, :a], [:lasgn, :b]],
     [:argspush,
      [:splat, [:call, nil, :foo, [:arglist]]],
      [:call, nil, :bar, [:arglist]]]]
  end
  
  # test_masgn_splat
  parse "a, *b = bar" do
    [:masgn,
     [:array, [:lasgn, :a], [:splat, [:lasgn, :b]]],
     [:call, nil, :bar, [:arglist]]]
  end
  
  # test_masgn_splat
  parse "a, *b, c = bar" do
    [:masgn,
     [:array, [:lasgn, :a], [:splat, [:lasgn, :b]]],
     [:lasgn, :c],
     [:call, nil, :bar, [:arglist]]]
  end
  
  # test_masgn_splat
  parse "a, * = bar" do
    [:masgn, [:array, [:lasgn, :a], [:splat]], [:call, nil, :bar, [:arglist]]]
  end
  
  # test_masgn_splat
  parse "a, *, c = bar" do
    [:masgn, [:array, [:lasgn, :a]], [:lasgn, :c], [:call, nil, :bar, [:arglist]]]
  end
  
  # test_masgn_splat
  parse "*b = bar" do
    [:masgn, [:array, [:splat, [:lasgn, :b]]], [:call, nil, :bar, [:arglist]]]
  end
  
  # test_masgn_splat
  parse "*b, c = bar" do
    [:masgn,
     [:array, [:splat, [:lasgn, :b]]],
     [:lasgn, :c],
     [:call, nil, :bar, [:arglist]]]
  end
  
  # test_masgn_splat
  parse "* = bar" do
    [:masgn, [:array, [:splat]], [:call, nil, :bar, [:arglist]]]
  end
  
  # test_masgn_splat
  parse "*, c, d = bar" do
    [:masgn, [:array], [:lasgn, :c], [:lasgn, :d], [:call, nil, :bar, [:arglist]]]
  end
  
  # test_send_lambda_args_shadow
  parse "->(a; foo, bar) { }" do
    [:lambda, [:args, :a], [:scope, [:nil]]]
  end
  
  # test_case_expr
  parse "case foo; when 'bar'; bar; end" do
    [:case,
     [:call, nil, :foo, [:arglist]],
     [:when, [:array, [:str, "bar"]], [:call, nil, :bar, [:arglist]]],
     nil]
  end
  
  # test_array_symbols
  parse "%i[foo bar]" do
    [:array, [:lit, :foo], [:lit, :bar]]
  end
  
  # test_kwrestarg_named
  parse "def f(**foo); end" do
    [:defn,
     :f,
     [:args, :"**foo", [:kwargs, [:"**foo"]]],
     [:scope, [:block, [:nil]]]]
  end
  
  # test_send_call
  parse "foo.(1)" do
    [:call, [:call, nil, :foo, [:arglist]], :call, [:arglist, [:lit, 1]]]
  end
  
  # test_send_call
  parse "foo::(1)" do
    [:call, [:call, nil, :foo, [:arglist]], :call, [:arglist, [:lit, 1]]]
  end
  
  # test_case_expr_else
  parse "case foo; when 'bar'; bar; else baz; end" do
    [:case,
     [:call, nil, :foo, [:arglist]],
     [:when, [:array, [:str, "bar"]], [:call, nil, :bar, [:arglist]]],
     [:call, nil, :baz, [:arglist]]]
  end
  
  # test_array_symbols_interp
  parse "%I[foo \#{bar}]" do
    [:array, [:dsym, "foo"], [:dsym, "", [:evstr, [:call, nil, :bar, [:arglist]]]]]
  end
  
  # test_array_symbols_interp
  parse "%I[foo\#{bar}]" do
    [:array, [:dsym, "foo", [:evstr, [:call, nil, :bar, [:arglist]]]]]
  end
  
  # test_masgn_nested
  parse "a, (b, c) = foo" do
    [:masgn,
     [:array, [:lasgn, :a], [:masgn, [:array, [:lasgn, :b], [:lasgn, :c]]]],
     [:call, nil, :foo, [:arglist]]]
  end
  
  # test_masgn_nested
  parse "((b, )) = foo" do
    [:masgn,
     [:array, [:masgn, [:array, [:lasgn, :b]]]],
     [:call, nil, :foo, [:arglist]]]
  end
  
  # test_lvar_injecting_match
  parse "/(?<match>bar)/ =~ 'bar'; match" do
    [:block,
     [:match2, [:regex, "(?<match>bar)", 0], [:str, "bar"]],
     [:call, nil, :match, [:arglist]]]
  end
  
  # test_case_cond
  parse "case; when foo; 'foo'; end" do
    [:case,
     nil,
     [:when, [:array, [:call, nil, :foo, [:arglist]]], [:str, "foo"]],
     nil]
  end
  
  # test_array_symbols_empty
  parse "%i[]" do
    [:array]
  end
  
  # test_array_symbols_empty
  parse "%I()" do
    [:array]
  end
  
  # test_masgn_attr
  parse "self.a, self[1, 2] = foo" do
    [:masgn,
     [:array,
      [:attrasgn, nil, :a=, [:arglist]],
      [:attrasgn, nil, :[]=, [:arglist, [:lit, 1], [:lit, 2]]]],
     [:call, nil, :foo, [:arglist]]]
  end
  
  # test_masgn_attr
  parse "self::a, foo = foo" do
    [:masgn,
     [:array, [:attrasgn, nil, :a=, [:arglist]], [:lasgn, :foo]],
     [:lvar, :foo]]
  end
  
  # test_masgn_attr
  parse "self.A, foo = foo" do
    [:masgn,
     [:array, [:attrasgn, nil, :A=, [:arglist]], [:lasgn, :foo]],
     [:lvar, :foo]]
  end
  
  # test_kwrestarg_unnamed
  parse "def f(**); end" do
    [:defn, :f, [:args, :**, [:kwargs, [:**]]], [:scope, [:block, [:nil]]]]
  end
  
  # test_case_cond_else
  parse "case; when foo; 'foo'; else 'bar'; end" do
    [:case,
     nil,
     [:when, [:array, [:call, nil, :foo, [:arglist]]], [:str, "foo"]],
     [:str, "bar"]]
  end
  
  # test_bom
  parse "\xEF\xBB\xBF1" do
    [:lit, 1]
  end
  
  # test_hash_empty
  parse "{ }" do
    [:hash]
  end
  
  # test_blockarg
  parse "def f(&block); end" do
    [:defn, :f, [:args, :"&block"], [:scope, [:block, [:nil]]]]
  end
  
  # test_non_lvar_injecting_match
  parse "/\#{'(?<match>bar)'}/ =~ 'bar'" do
    [:match2, [:regex, "(?<match>bar)", 0], [:str, "bar"]]
  end
  
  # # ERROR in: test_case_cond_just_else
  # parse "case; else 'bar'; end"
  
  # # ERROR in: test_magic_encoding_comment
  # parse "# coding:koi8-r\n           \xD0\xD2\xCF\xD7\xC5\xD2\xCB\xC1 = 42\n           puts \xD0\xD2\xCF\xD7\xC5\xD2\xCB\xC1"
  
  # test_hash_hashrocket
  parse "{ 1 => 2 }" do
    [:hash, [:lit, 1], [:lit, 2]]
  end
  
  # test_hash_hashrocket
  parse "{ 1 => 2, :foo => \"bar\" }" do
    [:hash, [:lit, 1], [:lit, 2], [:lit, :foo], [:str, "bar"]]
  end
  
  # test_super
  parse "super(foo)" do
    [:super, [:call, nil, :foo, [:arglist]]]
  end
  
  # test_super
  parse "super foo" do
    [:super, [:call, nil, :foo, [:arglist]]]
  end
  
  # test_super
  parse "super()" do
    [:super]
  end
  
  # test_when_then
  parse "case foo; when 'bar' then bar; end" do
    [:case,
     [:call, nil, :foo, [:arglist]],
     [:when, [:array, [:str, "bar"]], [:call, nil, :bar, [:arglist]]],
     nil]
  end
  
end
