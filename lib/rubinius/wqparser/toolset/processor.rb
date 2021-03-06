
class CodeTools::Processor < Parser::Builders::Default
  
  AST = CodeTools::AST
  
  #
  # Literals
  #
  
  # Singletons
  
  def nil(token)
    AST::NilLiteral.new line(token)
  end
  
  def true(token)
    AST::TrueLiteral.new line(token)
  end
  
  def false(token)
    AST::FalseLiteral.new line(token)
  end
  
  # Numerics
  
  def integer(token)
    value = value(token)
    if value.is_a?(Bignum)
      AST::NumberLiteral.new line(token), value
    else
      AST::FixnumLiteral.new line(token), value
    end
  end
  
  def float(token)
    AST::FloatLiteral.new line(token), value(token)
  end
  
  def rational(token)
    AST::RationalLiteral.new line(token), value(token)
  end
  
  def complex(token)
    AST::ImaginaryLiteral.new line(token), value(token)
  end
  
  def negate(token, numeric)
    numeric.value *= -1
    numeric
  end
  
  def __LINE__(token)
    value = line(token)
    if value.is_a?(Bignum)
      AST::NumberLiteral.new line(token), value
    else
      AST::FixnumLiteral.new line(token), value
    end
  end
  
  # Strings
  
  def string(token)
    AST::StringLiteral.new line(token), value(token)
  end
  
  def string_internal(token)
    string(token)
  end
  
  def string_compose(begin_t, parts, end_t)
    dynamic, line, string, parts = compose_parts(parts)
    
    if dynamic
      AST::DynamicString.new line, string, parts
    else
      string
    end
  end
  
  def character(token)
    AST::StringLiteral.new line(token), value(token)
  end
  
  def __FILE__(token)
    AST::File.new line(token)
  end
  
  # Symbols
  
  def symbol(token)
    AST::SymbolLiteral.new line(token), value(token).to_sym
  end
  
  def symbol_internal(token)
    symbol(token)
  end
  
  def symbol_compose(begin_t, parts, end_t)
    dynamic, line, string, parts = compose_parts(parts)
    
    if dynamic
      AST::DynamicSymbol.new line, string, parts
    else
      AST::SymbolLiteral.new line, string.string.to_sym
    end
  end
  
  # Executable strings
  
  def xstring_compose(begin_t, parts, end_t)
    dynamic, line, string, parts = compose_parts(parts)
    
    if dynamic
      AST::DynamicExecuteString.new line, string, parts
    else
      AST::ExecuteString.new line, string.string
    end
  end
  
  # Regular expressions
  
  def regexp_options(regopt_t)
    opt_convert = {
      'i' => 1, # RE_OPTION_IGNORECASE
      'm' => 2, # RE_OPTION_EXTENDED
      'x' => 4, # RE_OPTION_MULTILINE
      'n' => (1 << 9), # RE_KCODE_NONE
      'e' => (2 << 9), # RE_KCODE_EUC
      's' => (3 << 9), # RE_KCODE_SJIS
      'u' => (4 << 9), # RE_KCODE_UTF8
      'o' => 0, # RE_OPTION_ONCE (8192, but ignored for literal Regexp)
    }
    value = value(regopt_t)
    
    [(value.include? 'o'),
     (value.each_char.map { |chr| opt_convert[chr] }.inject(&:+) or 0)]
  end
  
  def regexp_compose(begin_t, parts, end_t, options)
    dynamic, line, string, parts = compose_parts(parts)
    once, options = options
    
    if dynamic
      once ? AST::DynamicOnceRegex.new(line, string, parts, options) :
             AST::DynamicRegex    .new(line, string, parts, options)
    else
      AST::RegexLiteral.new line, string.string, options
    end
  end
  
  # Arrays
  
  def array(begin_t, elements, end_t)
    line = line(begin_t)
    elements ||= []
    
    if elements.detect { |x| x.is_a?(AST::SplatValue) }
      if elements.empty?
        AST::NilLiteral.new line
      elsif elements.one?
        element = elements.first
        if element.is_a? AST::SplatValue
          if element.instance_variable_get :@sated
            element = AST::ArrayLiteral.new line, [element]
          else
            element.instance_variable_set :@sated, true
          end
        end
        element
      else
        _make_concat_args(line, elements)
      end
    else
      AST::ArrayLiteral.new line, elements
    end
  end
  
  def _make_concat_args(line, elements)
    rest = elements.pop
    rest = rest.value if rest.respond_to? :value
    array = AST::ArrayLiteral.new line, elements
    AST::ConcatArgs.new line, array, rest
  end
  
  def splat(star_t, arg=nil)
    if arg
      AST::SplatValue.new line(star_t), arg
    else
      AST::EmptySplat.new line(star_t), arg
    end
  end
  
  def word(parts)
    string_compose(nil, parts, nil)
  end
  
  def words_compose(begin_t, parts, end_t)
    AST::ArrayLiteral.new line(begin_t), parts
  end
  
  def symbols_compose(begin_t, parts, end_t)
    parts = parts.map do |part|
      if part.class == AST::StringLiteral
        AST::DynamicSymbol.new part.line, part.string, []
      elsif part.class == AST::DynamicString
        AST::DynamicSymbol.new part.line, part.string, part.array
      else
        part
      end
    end
    
    AST::ArrayLiteral.new line(begin_t), parts
  end
  
  # Hashes
  
  def pair(key, assoc_t, value)
    [key, value]
  end
  
  def pair_keyword(key_t, value)
    key = AST::SymbolLiteral.new line(key_t), value(key_t).to_sym
    [key, value]
  end
  
  def kwsplat(dstar_t, arg)
    [:kwsplat, arg]
  end
  
  def associate(begin_t, pairs, end_t)
    pairs.each { |pair| pair[0] = nil if pair[0]==:kwsplat }
    AST::HashLiteral.new line(begin_t), pairs.flatten
  end
  
  # Ranges
  
  def range_inclusive(lhs, dot2_t, rhs)
    AST::Range.new line(dot2_t), lhs, rhs
  end
  
  def range_exclusive(lhs, dot3_t, rhs)
    AST::RangeExclude.new line(dot3_t), lhs, rhs
  end
  
  #
  # Access
  #
  
  def self(token)
    AST::Self.new line(token)
  end
  
  def ident(token)
    receiver = AST::Self.new line(token)
    AST::Send.new line(token), receiver, value(token).to_sym, true
  end
  
  def ivar(token)
    AST::InstanceVariableAccess.new line(token), value(token).to_sym
  end
  
  def gvar(token)
    AST::GlobalVariableAccess.new line(token), value(token).to_sym
  end
  
  def cvar(token)
    AST::ClassVariableAccess.new line(token), value(token).to_sym
  end
  
  def back_ref(token)
    AST::BackRef.new line(token), value(token)[1..-1].to_sym
  end
  
  def nth_ref(token)
    AST::NthRef.new line(token), value(token)
  end
  
  def accessible(node)
    if node.is_a?(AST::Send) && node.privately \
    && @parser.static_env.declared?(node.name)
      AST::LocalVariableAccess.new node.line, node.name
    else
      node
    end
  end
  
  def const(token)
    AST::ConstantAccess.new line(token), value(token).to_sym
  end
  
  def const_global(t_colon3, token)
    AST::ToplevelConstant.new line(token), value(token).to_sym
  end
  
  def const_fetch(outer, t_colon2, token)
    line = line(token)
    name = value(token).to_sym
    
    if outer
      if outer.kind_of? AST::ConstantAccess and
         outer.name == :Rubinius
        case name
        when :Type
          AST::TypeConstant.new line
        when :Mirror
          AST::MirrorConstant.new line
        else
          AST::ScopedConstant.new line, outer, name
        end
      else
        AST::ScopedConstant.new line, outer, name
      end
    else
      AST::ConstantAccess.new line, name
    end
  end
  
  def __ENCODING__(__ENCODING__t)
    encoding_name = __ENCODING__t.first.encoding.name
    AST::Encoding.new line(__ENCODING__t), encoding_name
  end
  
  #
  # Assignment
  #
  
  def assignable(node)
    if node.is_a?(AST::Send) && node.privately
      @parser.static_env.declare(node.name)
      node = AST::LocalVariableAccess.new node.line, node.name
    elsif node.is_a?(AST::LocalVariableAccess)
      @parser.static_env.declare(node.name)
    elsif node.is_a?(AST::LocalVariableAssignment)
      @parser.static_env.declare(node.name)
    end
    
    node
  end
  
  # def const_op_assignable(node)
  #   node.updated(:casgn)
  # end
  
  def assign(lhs, eql_t, rhs)
    convert_to_assignment line(eql_t), lhs, rhs
  end
  
  def op_assign(lhs, op_t, rhs)
    line = lhs.line
    name = value(op_t).to_sym
    
    if lhs.is_a?(AST::Send)
      if lhs.name == :[]
        ary = AST::ArrayLiteral.new line, lhs.arguments.array
        AST::OpAssignElement.new line, lhs.receiver, ary, name, rhs
      else
        AST::OpAssignAttribute.new line, lhs.receiver, lhs.name, name, rhs
      end
    else
      lhs = assignable(lhs)
      
      case name
      when :'&&'
        rhs_asgn = convert_to_assignment line, lhs, rhs
        AST::OpAssignAnd.new line, lhs, rhs_asgn
      when :'||'
        rhs_asgn = convert_to_assignment line, lhs, rhs
        AST::OpAssignOr.new line, lhs, rhs_asgn
      else;
        convert_to_assignment line, lhs,
          AST::SendWithArguments.new(line, lhs, name, rhs)
      end
    end
  end
  
  def multi_lhs(begin_t, items, end_t)
    line = line(begin_t)
    
    # For the special case of masgn in parameters
    if items.map { |x| x.is_a? Array and x.first.is_a? Symbol }.all?
      return param_multi_lhs(line, items)
    end
    
    items = items.map { |item| convert_to_assignment line, item, nil }
    AST::ArrayLiteral.new line, items
  end
  
  def param_multi_lhs(line, items)
    saw_splat = false
    post_items = []
    items = items.map do |type, value|
      case type
      when :splat
        saw_splat = true
        if value == :*
          masgn = AST::MultipleAssignment.new line, nil, nil, true
          return [:masgn, masgn]
        end
        value = AST::LocalVariableAssignment.new line, value
        AST::SplatValue.new line, value
      when :required
        new_item = AST::LocalVariableAssignment.new line, value
        saw_splat ? (post_items << new_item; nil) : new_item
      when :masgn
        value
      else
        type
      end
    end.compact
    lhs = AST::ArrayLiteral.new line, items
    masgn = AST::MultipleAssignment.new line, lhs, nil, nil
    post = AST::ArrayLiteral.new line, post_items
    masgn.post = post unless post_items.empty?
    [:masgn, masgn]
  end
  
  def multi_assign(lhs, eql_t, rhs)
    AST::MultipleAssignment.new line(eql_t), lhs, rhs, nil
  end
  
  #
  # Class and module definition
  #
  
  def def_class(class_t, name, lt_t, superclass, body, end_t)
    line = line(class_t)
    name = name.name if name.is_a? AST::ConstantAccess
    body = prepare_module_body(line, body)
    
    AST::Class.new line, name, superclass, body
  end
  
  def def_sclass(class_t, lshft_t, expr, body, end_t)
    line = line(class_t)
    name = name.name if name.is_a? AST::ConstantAccess
    body = prepare_module_body(line, body)
    
    AST::SClass.new line, expr, body
  end
  
  def def_module(module_t, name, body, end_t)
    line = line(module_t)
    name = name.name if name.is_a? AST::ConstantAccess
    body = prepare_module_body(line, body)
    
    AST::Module.new line, name, body
  end
  
  #
  # Method (un)definition
  #
  
  def def_method(def_t, name_t, args, body, end_t)
    line = line(def_t)
    name = value(name_t).to_sym
    body = AST::Block.new line, [body] unless body.is_a? AST::Block
    body.array.unshift args
    
    AST::Define.new line, name, body
  end
  
  def def_singleton(def_t, definee, dot_t, name_t, args, body, end_t)
    line = line(def_t)
    name = value(name_t).to_sym
    body = AST::Block.new line, [body] unless body.is_a? AST::Block
    body.array.unshift args
    
    AST::DefineSingleton.new line, definee, name, body
  end
  
  def undef_method(undef_t, names)
    line = line(undef_t)
    compstmt names.map { |name| AST::Undef.new line, name }
  end
  
  def alias(alias_t, to, from)
    if to.is_a? AST::GlobalVariableAccess
      v_to = to.name
    elsif to.is_a? AST::BackRef
      v_to = :"$#{to.kind}"
    end
    
    if from.is_a? AST::GlobalVariableAccess
      v_from = from.name
    elsif from.is_a? AST::BackRef
      v_from = :"$#{from.kind}"
    end
    
    if v_to && v_from
      AST::VAlias.new line(alias_t), v_to, v_from
    else
      AST::Alias.new line(alias_t), to, from
    end
  end
  
  #
  # Formal arguments
  #
  
  def _consume_consecutive_args(args, type)
    [].tap do |ary|
      ary.push args.shift.last until args.empty? or args.first.first != type
    end
  end
  
  def _consume_possible_arg(args, type)
    args.shift.last unless args.empty? or args.first.first != type
  end
  
  def args(begin_t, args, end_t, check_args=true)
    line = begin_t ? line(begin_t) : 0
    
    masgn     = []
    required  = _consume_consecutive_args args, :required
    required += _consume_consecutive_args args, :masgn
    optional  = _consume_consecutive_args args, :optional
    splat     = _consume_possible_arg     args, :splat
    post      = _consume_consecutive_args args, :required
    post     += _consume_consecutive_args args, :masgn
    kwargs    = _consume_consecutive_args args, :kwarg
    kwrest    = _consume_possible_arg     args, :kwrest
    block     = _consume_possible_arg     args, :block
    shadows   = _consume_consecutive_args args, :shadow
    
    if optional.empty?
      optional = nil
    else
      optional.map! { |a| AST::LocalVariableAssignment.new *a }
      optional = AST::Block.new line, optional
    end
    
    if kwargs.empty?
      kwargs = nil
    else
      kwargs.map! { |a| AST::LocalVariableAssignment.new *a }
      kwargs = AST::Block.new line, kwargs
    end
    
    params = AST::Parameters.new line,
      required, optional, splat, post, kwargs, kwrest, block
    
    unless shadows.empty?
      shadows = AST::ArrayLiteral.new line, shadows
      params.instance_variable_set :@shadows, shadows
    end
    
    params
  end
  
  def arg(token)
    [:required, value(token).to_sym]
  end
  
  def optarg(name_t, eql_t, value)
    [:optional, [line(eql_t), value(name_t).to_sym, value]]
  end
  
  def restarg(star_t, name_t=nil)
    value = name_t ? value(name_t).to_sym : :*
    [:splat, value]
  end
  
  def kwarg(name_t)
    value = AST::SymbolLiteral.new line(name_t), :*
    [:kwarg, [line(name_t), value(name_t).to_sym, value]]
  end
  
  def kwoptarg(name_t, value)
    [:kwarg, [line(name_t), value(name_t).to_sym, value]]
  end
  
  def kwrestarg(dstar_t, name_t=nil)
    [:kwrest, name_t ? value(name_t).to_sym : true]
  end
  
  def shadowarg(name_t)
    shadow = AST::SymbolLiteral.new line(name_t), value(name_t).to_sym
    [:shadow, shadow]
  end
  
  def blockarg(amper_t, name_t)
    [:block, value(name_t).to_sym]
  end
  
  #
  # Method calls
  #
  
  def call_method(receiver, dot_t, selector_t,
                  lparen_t=nil, args=[], rparen_t=nil)
    line = receiver ? receiver.line : line(selector_t)
    name = selector_t ? value(selector_t).to_sym : :call
    vcall = receiver.nil?
    receiver = AST::Self.new line if vcall
    
    if args.empty?
      AST::Send.new line, receiver, name, vcall
    else
      args = AST::ArrayLiteral.new line, args
      AST::SendWithArguments.new line, receiver, name, args, vcall
    end
  end
  
  def call_lambda(lambda_t)
    :lambda
  end
  
  def block(method_call, begin_t, args, body, end_t)
    if method_call == :lambda
      return AST::Lambda.new line(begin_t), args, body
    end
    
    shadows = args.instance_variable_get :@shadows
    if shadows
      if body.is_a? AST::NilLiteral
        body = AST::Block.new line(begin_t), []
      end
      
      unless body.is_a? AST::Block
        body = AST::Block.new line(begin_t), [body]
      end
      
      body.locals = shadows
    end
    
    method_call.block = AST::Iter.new line(begin_t), args, body
    
    method_call
    
    # _receiver, _selector, *call_args = *method_call
    
    # if method_call.type == :yield
    #   diagnostic :error, :block_given_to_yield, nil, method_call.loc.keyword, [loc(begin_t)]
    # end
    
    # last_arg = call_args.last
    # if last_arg && last_arg.type == :block_pass
    #   diagnostic :error, :block_and_blockarg, nil, last_arg.loc.expression, [loc(begin_t)]
    # end
    
    # if [:send, :super, :zsuper].include?(method_call.type)
    #   n(:block, [ method_call, args, body ],
    #     block_map(method_call.loc.expression, begin_t, end_t))
    # else
    #   # Code like "return foo 1 do end" is reduced in a weird sequence.
    #   # Here, method_call is actually (return).
    #   actual_send, = *method_call
    #   block =
    #     n(:block, [ actual_send, args, body ],
    #       block_map(actual_send.loc.expression, begin_t, end_t))
    
    #   n(method_call.type, [ block ],
    #     method_call.loc.with_expression(join_exprs(method_call, block)))
    # end
  end
  
  def block_pass(amper_t, arg)
    AST::BlockPass.new line(amper_t), arg
  end
  
  def attr_asgn(receiver, dot_t, selector_t)
    AST::AttributeAssignment.new \
      line(dot_t), receiver, value(selector_t).to_sym, []
  end
  
  def index(receiver, lbrack_t, indexes, rbrack_t)
    line = line(lbrack_t)
    args = AST::ArrayLiteral.new line, indexes
    
    AST::SendWithArguments.new line, receiver, :[], args
  end
  
  def index_asgn(receiver, lbrack_t, indexes, rbrack_t)
    line = line(lbrack_t)
    args = AST::ArrayLiteral.new line, indexes
    
    AST::ElementAssignment.new line, receiver, args
  end
  
  def binary_op(receiver, operator_t, arg)
    line = receiver.line
    name = value(operator_t).to_sym
    
    AST::SendWithArguments.new line, receiver, name, arg
  end
  
  def match_op(receiver, match_t, arg)
    line = receiver.line
    
    if receiver.is_a? AST::DynamicRegex \
    or receiver.is_a? AST::RegexLiteral
      AST::Match2.new line, receiver, arg
    else
      AST::Match3.new line, arg, receiver
    end
  end
  
  def unary_op(op_t, receiver)
    method = value(op_t)
    method += '@' if '+'==method or '-'==method
    
    AST::Send.new line(op_t), receiver, method.to_sym
  end
  
  def not_op(not_t, begin_t=nil, receiver=nil, end_t=nil)
    # AST::Not.new line(not_t), receiver
    AST::Send.new line(not_t), receiver, :'!'
  end
  
  #
  # Control flow
  #
  
  # Logical operations: and, or
  
  def logical_op(type, lhs, op_t, rhs)
    line = line(op_t)
    
    case type
    when :and
      AST::And.new line, lhs, rhs
    when :or
      AST::Or.new line, lhs, rhs
    else
      raise NotImplementedError, "logical_op type: #{type}"
    end
  end
  
  # Conditionals
  
  def condition(cond_t, cond, then_t, if_true, else_t, if_false, end_t)
    AST::If.new line(cond_t), check_condition(cond), if_true, if_false
  end
  
  def condition_mod(if_true, if_false, cond_t, cond)
    AST::If.new line(cond_t), check_condition(cond), if_true, if_false
  end
  
  def ternary(cond, question_t, if_true, colon_t, if_false)
    AST::If.new line(question_t), check_condition(cond), if_true, if_false
  end
  
  # Case matching
  
  def when(when_t, patterns, then_t, body)
    patterns = AST::ArrayLiteral.new line(when_t), patterns
    AST::When.new line(when_t), patterns, body
  end
  
  def case(case_t, expr, when_bodies, else_t, else_body, end_t)
    else_body = AST::Begin.new else_body.line, else_body \
      if else_body.is_a? AST::NilLiteral
    
    if expr.nil?
      AST::Case.new line(case_t), when_bodies, else_body
    else
      AST::ReceiverCase.new line(case_t), expr, when_bodies, else_body
    end
  end
  
  # Loops
  
  def loop(type, keyword_t, cond, do_t, body, end_t)
    line = line(keyword_t)
    check_first = true
    
    case type
    when :while
      AST::While.new line, check_condition(cond), body, check_first
    when :until
      AST::Until.new line, check_condition(cond), body, check_first
    else
      raise NotImplementedError, "loop type: #{type}"
    end
  end
  
  def loop_mod(type, body, keyword_t, cond)
    line = line(keyword_t)
    check_first = !body.is_a?(AST::Begin)
    
    case type
    when :while
      AST::While.new line, check_condition(cond), body, check_first
    when :until
      AST::Until.new line, check_condition(cond), body, check_first
    else
      raise NotImplementedError, "loop_mod type: #{type}"
    end
  end
  
  def for(for_t, iterator, in_t, iteratee, do_t, body, end_t)
    line = line(for_t)
    iterator = convert_to_assignment line(in_t), iterator, nil
    
    send = AST::Send.new line, iteratee, :each
    send.block = AST::For.new line, iterator, body
    send
  end
  
  # Keywords
  
  def keyword_cmd(type, keyword_t, lparen_t=nil, elements=[], rparen_t=nil)
    line = line(keyword_t)
    value = \
      if elements.empty?
        nil
      elsif elements.one?
        element = elements.first
        
        if type == :yield or type == :super
          if element.is_a?(AST::SplatValue)
            if (element.instance_variable_get :@sated)
              element = AST::ArrayLiteral.new line, elements
            end
          else
            element = AST::ArrayLiteral.new line, elements
          end
        end
        
        element
      else
        x = elements.last
        if x.is_a?(AST::SplatValue) or x.is_a?(AST::Send) or x.is_a?(AST::SendWithArguments)
          rest = elements.pop.value
          array = AST::ArrayLiteral.new line, elements
          AST::ConcatArgs.new line, array, rest
        else
          AST::ArrayLiteral.new line, elements
        end
      end
    
    case type
    when :return
      AST::Return.new line, value
    when :super
      AST::Super.new line, value
    when :zsuper
      AST::ZSuper.new line
    when :defined?
      AST::Defined.new line, value
    when :yield
      AST::Yield.new line, value, true
    when :break
      AST::Break.new line, value
    when :redo
      AST::Redo.new line
    when :retry
      AST::Retry.new line
    when :next
      AST::Next.new line, value
    else
      raise NotImplementedError, "keyword_cmd type: #{type}"
    end
  end
  
  # BEGIN, END
  
  def preexe(preexe_t, lbrace_t, compstmt, rbrace_t)
    line = line(preexe_t)
    body = AST::Block.new line, [compstmt]
    
    node = AST::PreExe19.new line
    node.block = AST::Iter.new line, nil, body
    # TODO: add_pre_exe node # as rubinius-processor does
    node
  end
  
  def postexe(postexe_t, lbrace_t, compstmt, rbrace_t)
    line = line(postexe_t)
    body = AST::Block.new line, [compstmt]
    
    node = AST::Send.new line, AST::Self.new(line), :at_exit, true
    node.block = AST::Iter.new line, nil, body
    node
  end
  
  # Exception handling
  
  def rescue_body(rescue_t, exc_list, assoc_t, exc_var, then_t, compound_stmt)
    blk = if exc_var
      line = line(assoc_t)
      last_e = AST::CurrentException.new line
      e_asgn = convert_to_assignment line, exc_var, last_e
      AST::Block.new compound_stmt.line, [e_asgn, compound_stmt]
    else
      AST::Block.new compound_stmt.line, [compound_stmt]
    end
    
    AST::RescueCondition.new line(rescue_t), exc_list, blk, nil
  end
  
  def begin_body(compound_stmt, rescue_bodies=[],
                 else_t=nil,    else_=nil,
                 ensure_t=nil,  ensure_=nil)
    first = nil
    last = nil
    rescue_bodies.each do |resbody|
      if last
        last.next = resbody
      else
        first = resbody
      end
      
      last = resbody
    end
    
    if rescue_bodies.any?
      compound_stmt = AST::Rescue.new line(else_t), compound_stmt, first, else_
    end
    
    if ensure_t
      compound_stmt = AST::Ensure.new line(ensure_t), compound_stmt, ensure_
    end
    
    compound_stmt
  end
  
  #
  # Expression grouping
  #
  
  def compstmt(statements)
    case
    when statements.none?
      AST::NilLiteral.new 0
    when statements.one?
      statements.first
    else
      statements.map! { |s| s.class==AST::Block ? s.array : s }.flatten!
      AST::Block.new statements.first.line, statements
    end
  end
  
  def begin(begin_t, body, end_t)
    if body.nil?
      AST::NilLiteral.new line(begin_t)
    else
      body
    end
  end
  
  def begin_keyword(begin_t, body, end_t)
    if body.nil?
      AST::NilLiteral.new line(begin_t)
    else
      AST::Begin.new line(begin_t), body
    end
  end
  
private
  
  def compose_parts(parts)
    line = parts.first ? parts.first.line : 0
    
    if parts.detect { |part| part.class != AST::StringLiteral }
      parts.map! do |part|
        if part.class == AST::StringLiteral
          part
        elsif part.class == AST::DynamicString
          str = AST::StringLiteral.new line, part.string
          (part.string.empty? ? [] : [str]) + part.array
        else
          AST::ToString.new line, part
        end
      end.flatten!
      
      # Get first non-dynamic part (or '')
      first = parts.shift.string if parts.first.class == AST::StringLiteral
      first ||= ''
      
      # Join adjacent non-dynamic parts
      clustered_parts = []
      [*parts].each do |element|
        if clustered_parts.last.class == AST::StringLiteral \
        && element.class == AST::StringLiteral
          clustered_parts.last.string += element.string
        else
          clustered_parts.push element
        end
      end
      
      return [true, line, first, clustered_parts]
    elsif parts.one?
      return [false, line, parts.first, []]
    else
      string = AST::StringLiteral.new line, parts.map(&:string).join
      return [false, line, string, []]
    end
  end
  
  def prepare_module_body(line, body)
    if body.is_a?(AST::NilLiteral)
      nil
    elsif body.is_a?(AST::Block)
      body
    else
      AST::Block.new line, [body]
    end
  end
  
  def convert_to_assignment(line, orig, value)
    kls = orig.class
    name = orig.name if orig.respond_to? :name
    
    if kls == AST::SplatValue
      orig.value = convert_to_assignment line, orig.value, value
      orig
    elsif kls == AST::EmptySplat
      orig
    elsif kls == AST::ArrayLiteral
      AST::MultipleAssignment.new line, orig, value, nil
    elsif kls == AST::Send
      AST::LocalVariableAssignment.new line, name, value
    elsif kls == AST::LocalVariableAccess
      AST::LocalVariableAssignment.new line, name, value
    elsif kls == AST::InstanceVariableAccess
      AST::InstanceVariableAssignment.new line, name, value
    elsif kls == AST::ClassVariableAccess
      AST::ClassVariableAssignment.new line, name, value
    elsif kls == AST::GlobalVariableAccess
      AST::GlobalVariableAssignment.new line, name, value
    elsif kls == AST::ConstantAccess
      AST::ConstantAssignment.new line, name, value
    elsif kls == AST::ToplevelConstant
      AST::ConstantAssignment.new line, orig, value
    elsif kls == AST::ScopedConstant
      AST::ConstantAssignment.new line, orig, value
    elsif kls == AST::AttributeAssignment
      orig.arguments = AST::Arguments.new line, value
      orig
    elsif kls == AST::ElementAssignment
      orig_args = orig.arguments.array
      
      if value.is_a? AST::ConcatArgs
        value = value.array.tap { |ary| ary.body << value.rest }
      end
      
      if orig_args.detect { |x| x.is_a? AST::SplatValue }
        push_args = if orig_args.count == 1
          orig.arguments = AST::PushArgs.new line, orig_args.first, value
        else
          concat_args = _make_concat_args line, orig_args
          orig.arguments = AST::PushArgs.new line, concat_args, value
        end
        AST::ElementAssignment.new line, orig.receiver, push_args
      else
        orig_args << value
        orig
      end
    else
      raise NotImplementedError, "convert_to_assignment with kls: #{kls}"
    end
  end
  
  def check_condition(cond)
    kls = cond.class
    
    if    kls == AST::RegexLiteral
      AST::Match.new cond.line, cond.source, cond.options
    elsif kls == AST::Range
      AST::Flip2.new cond.line, cond.start, cond.finish
    elsif kls == AST::RangeExclude
      AST::Flip3.new cond.line, cond.start, cond.finish
    else
      cond
    end
  end
  
  def line(token)
    token ? loc(token).line : 0
  end
  
  # # A crude call/argument/exception tracer for debugging
  # this_class = self
  # prepend Module.new {
  #   this_class.instance_methods.each do |sym|
  #     define_method sym do |*args, &block|
  #       begin
  #         (pp [sym, *args]; puts)
  #         super *args, &block
  #       rescue Exception=>e
  #         p sym
  #         puts; p e
  #         puts; e.backtrace.each { |line| puts line }
  #         puts
  #         raise e
  #       end
  #     end
  #   end
  # }
end
