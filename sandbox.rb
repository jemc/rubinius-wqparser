
require 'pry'
require 'deco'

require 'rubinius/toolset'
require 'rubinius/compiler'
require 'rubinius/ast'

require 'parser/current'

RBX = Rubinius::ToolSet.current::TS

# module RBX; end
# module RBX::AST; end

# class Parser::AST::Node
#   def initialize
#     p [:whup, caller]
#   end
# end

class RubiniusBuilder < Parser::Builders::Default
  
  #
  # Literals
  #
  
  # Singletons
  
  def nil(token)
    RBX::AST::NilLiteral.new line(token)
  end
  
  def true(token)
    RBX::AST::TrueLiteral.new line(token)
  end
  
  def false(token)
    RBX::AST::FalseLiteral.new line(token)
  end
  
  # Numerics
  
  def integer(token);  numeric(token) end
  def float(token);    numeric(token) end
  def rational(token); numeric(token) end
  def complex(token);  numeric(token) end
  
  def numeric(token)
    value = value(token)
    value.is_a?(Bignum) ?
      RBX::AST::NumberLiteral.new(line(token), value) :
      RBX::AST::FixnumLiteral.new(line(token), value)
  end
  private :numeric
  
  def negate(token, numeric)
    numeric.value *= -1
    numeric
  end
  
  def __LINE__(token)
    value = line(token)
    value.is_a?(Bignum) ?
      RBX::AST::NumberLiteral.new(line(token), value) :
      RBX::AST::FixnumLiteral.new(line(token), value)
  end
  
  # Strings
  
  def string(token)
    RBX::AST::StringLiteral.new line(token), value(token)
  end
  
  def string_internal(token)
    string(token)
  end
  
  def string_compose(begin_t, parts, end_t)
    dynamic, line, string, parts = compose_parts(parts)
    
    if dynamic
      RBX::AST::DynamicString.new line, string, parts
    else
      string
    end
  end
  
  def character(token)
    RBX::AST::StringLiteral.new line(token), value(token)
  end
  
  def __FILE__(token)
    RBX::AST::File.new line(token)
  end
  
  # Symbols
  
  def symbol(token)
    RBX::AST::SymbolLiteral.new line(token), value(token).to_sym
  end
  
  def symbol_internal(token)
    symbol(token)
  end
  
  def symbol_compose(begin_t, parts, end_t)
    dynamic, line, string, parts = compose_parts(parts)
    
    if dynamic
      RBX::AST::DynamicSymbol.new line, string, parts
    else
      RBX::AST::SymbolLiteral.new line, string.string.to_sym
    end
  end
  
  # Executable strings
  
  def xstring_compose(begin_t, parts, end_t)
    dynamic, line, string, parts = compose_parts(parts)
    
    if dynamic
      RBX::AST::DynamicExecuteString.new line, string, parts
    else
      RBX::AST::ExecuteString.new line, string.string
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
      once ? RBX::AST::DynamicOnceRegex.new(line, string, parts, options) :
             RBX::AST::DynamicRegex    .new(line, string, parts, options)
    else
      RBX::AST::RegexLiteral.new line, string.string, options
    end
  end
  
  
  # Arrays

  def array(begin_t, elements, end_t)
    line = line(begin_t)
    elements ||= []
    
    if elements.detect { |x| x.is_a?(RBX::AST::SplatValue) \
    or x.is_a?(RBX::AST::Send) or x.is_a?(RBX::AST::SendWithArguments) }
      if elements.empty?
        RBX::AST::NilLiteral.new line
      elsif elements.one?
        element = elements.first
        if element.is_a? RBX::AST::SplatValue
          if element.instance_variable_get :@sated
            element = RBX::AST::ArrayLiteral.new line, [element]
          else
            element.instance_variable_set :@sated, true
          end
        end
        element
      else
        rest = elements.pop
        rest = rest.value if rest.respond_to? :value
        array = RBX::AST::ArrayLiteral.new line, elements
        RBX::AST::ConcatArgs.new line, array, rest
      end
    else
      RBX::AST::ArrayLiteral.new line, elements
    end
  end

  def splat(star_t, arg=nil)
    RBX::AST::SplatValue.new line(star_t), arg
  end

  def word(parts)
    string_compose(nil, parts, nil)
  end

  def words_compose(begin_t, parts, end_t)
    RBX::AST::ArrayLiteral.new line(begin_t), parts
  end

  # def symbols_compose(begin_t, parts, end_t)
  #   parts = parts.map do |part|
  #     case part.type
  #     when :str
  #       value, = *part
  #       part.updated(:sym, [ value.to_sym ])
  #     when :dstr
  #       part.updated(:dsym)
  #     else
  #       part
  #     end
  #   end

  #   n(:array, [ *parts ],
  #     collection_map(begin_t, parts, end_t))
  # end

  # Hashes

  def pair(key, assoc_t, value)
    [key, value]
  end

  # def pair_list_18(list)
  #   if list.size % 2 != 0
  #     diagnostic :error, :odd_hash, nil, list.last.loc.expression
  #   else
  #     list.
  #       each_slice(2).map do |key, value|
  #         n(:pair, [ key, value ],
  #           binary_op_map(key, nil, value))
  #       end
  #   end
  # end

  # def pair_keyword(key_t, value)
  #   key_map, pair_map = pair_keyword_map(key_t, value)

  #   key = n(:sym, [ value(key_t).to_sym ], key_map)

  #   n(:pair, [ key, value ], pair_map)
  # end

  # def kwsplat(dstar_t, arg)
  #   n(:kwsplat, [ arg ],
  #     unary_op_map(dstar_t, arg))
  # end

  def associate(begin_t, pairs, end_t)
    RBX::AST::HashLiteral.new line(begin_t), pairs.flatten
  end

  # Ranges

  def range_inclusive(lhs, dot2_t, rhs)
    RBX::AST::Range.new line(dot2_t), lhs, rhs
  end

  def range_exclusive(lhs, dot3_t, rhs)
    RBX::AST::RangeExclude.new line(dot3_t), lhs, rhs
  end
  
  #
  # Access
  #

  def self(token)
    RBX::AST::Self.new line(token)
  end

  def ident(token)
    receiver = RBX::AST::Self.new line(token)
    RBX::AST::Send.new line(token), receiver, value(token).to_sym, true
  end

  def ivar(token)
    RBX::AST::InstanceVariableAccess.new line(token), value(token).to_sym
  end

  def gvar(token)
    RBX::AST::GlobalVariableAccess.new line(token), value(token).to_sym
  end

  def cvar(token)
    RBX::AST::ClassVariableAccess.new line(token), value(token).to_sym
  end

  def back_ref(token)
    RBX::AST::BackRef.new line(token), value(token)[1..-1].to_sym
  end

  def nth_ref(token)
    RBX::AST::NthRef.new line(token), value(token)
  end
  
  def accessible(node)
    if node.is_a?(RBX::AST::Send) && node.privately \
    && @parser.static_env.declared?(node.name)
      RBX::AST::LocalVariableAccess.new node.line, node.name
    else
      node
    end
  end
  
  def const(token)
    RBX::AST::ConstantAccess.new line(token), value(token).to_sym
  end

  def const_global(t_colon3, token)
    RBX::AST::ToplevelConstant.new line(token), value(token).to_sym
  end

  def const_fetch(outer, t_colon2, token)
    line = line(token)
    name = value(token).to_sym
    
    if outer
      if outer.kind_of? RBX::AST::ConstantAccess and
         outer.name == :Rubinius
        case name
        when :Type
          RBX::AST::TypeConstant.new line
        when :Mirror
          RBX::AST::MirrorConstant.new line
        else
          RBX::AST::ScopedConstant.new line, outer, name
        end
      else
        RBX::AST::ScopedConstant.new line, outer, name
      end
    else
      RBX::AST::ConstantAccess.new line, name
    end
  end

  # def __ENCODING__(__ENCODING__t)
  #   n0(:__ENCODING__,
  #     token_map(__ENCODING__t))
  # end


  #
  # Assignment
  #

  def assignable(node)
    
    if node.is_a?(RBX::AST::Send) && node.privately
      @parser.static_env.declare(node.name)
      # if node.privately
        node = RBX::AST::LocalVariableAccess.new node.line, node.name
      # elsif node.receiver
        # assignable(node.receiver)# if node.respond_to? :receiver
        # node = RBX::AST::AttributeAssignment.new \
        #   node.line, assignable(node.receiver), node.name, []
        # p nod
        # node = RBX::AST::
      # end
    elsif node.is_a?(RBX::AST::LocalVariableAccess)
      @parser.static_env.declare(node.name)
    elsif node.is_a?(RBX::AST::LocalVariableAssignment)
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
    
    if lhs.is_a?(RBX::AST::Send)
      if lhs.name == :[]
        ary = RBX::AST::ArrayLiteral.new line, lhs.arguments.array
        RBX::AST::OpAssign1.new line, lhs.receiver, ary, name, rhs
      else
        RBX::AST::OpAssign2.new line, lhs.receiver, lhs.name, name, rhs
      end
    else
      lhs = assignable(lhs)
      rhs = convert_to_assignment(line, lhs, rhs)
      
      case name
      when :'&&'; RBX::AST::OpAssignAnd.new line, lhs, rhs
      when :'||'; RBX::AST::OpAssignOr.new line, lhs, rhs
      else;
        nil
      end
      # RBX::AST::OpAssign2.new line, lhs, rhs
    end
    
    # case lhs.type
    # when :gvasgn, :ivasgn, :lvasgn, :cvasgn, :casgn, :send
    #   operator   = value(op_t)[0..-1].to_sym
    #   source_map = lhs.loc.
    #                   with_operator(loc(op_t)).
    #                   with_expression(join_exprs(lhs, rhs))

    #   case operator
    #   when :'&&'
    #     n(:and_asgn, [ lhs, rhs ], source_map)
    #   when :'||'
    #     n(:or_asgn, [ lhs, rhs ], source_map)
    #   else
    #     n(:op_asgn, [ lhs, operator, rhs ], source_map)
    #   end

    # when :back_ref, :nth_ref
    #   diagnostic :error, :backref_assignment, nil, lhs.loc.expression
    # end
  end
  
  # def multi_lhs(begin_t, items, end_t)
  #   n(:mlhs, [ *items ],
  #     collection_map(begin_t, items, end_t))
  # end
  
  # def multi_assign(lhs, eql_t, rhs)
  #   n(:masgn, [ lhs, rhs ],
  #     binary_op_map(lhs, eql_t, rhs))
  # end
  
  #
  # Class and module definition
  #
  
  def def_class(class_t, name, lt_t, superclass, body, end_t)
    line = line(class_t)
    name = name.name if name.is_a? RBX::AST::ConstantAccess
    body = prepare_module_body(line, body)
    
    RBX::AST::Class.new line, name, superclass, body
  end
  
  def def_sclass(class_t, lshft_t, expr, body, end_t)
    line = line(class_t)
    name = name.name if name.is_a? RBX::AST::ConstantAccess
    body = prepare_module_body(line, body)
    
    RBX::AST::SClass.new line, expr, body
  end
  
  def def_module(module_t, name, body, end_t)
    line = line(module_t)
    name = name.name if name.is_a? RBX::AST::ConstantAccess
    body = prepare_module_body(line, body)
    
    RBX::AST::Module.new line, name, body
  end
  
  
  #
  # Method (un)definition
  #

  def def_method(def_t, name_t, args, body, end_t)
    line = line(def_t)
    name = value(name_t).to_sym
    body = RBX::AST::Block.new line, [body] unless body.is_a? RBX::AST::Block
    body.array.unshift args
    
    RBX::AST::Define.new line, name, body
  end

  def def_singleton(def_t, definee, dot_t, name_t, args, body, end_t)
    line = line(def_t)
    name = value(name_t).to_sym
    body = RBX::AST::Block.new line, [body] unless body.is_a? RBX::AST::Block
    body.array.unshift args
    
    RBX::AST::DefineSingleton.new line, definee, name, body
  end

  def undef_method(undef_t, names)
    line = line(undef_t)
    compstmt names.map { |name| RBX::AST::Undef.new line, name }
  end

  def alias(alias_t, to, from)
    if to  .is_a?(RBX::AST::GlobalVariableAccess) \
    && from.is_a?(RBX::AST::GlobalVariableAccess)
      RBX::AST::VAlias.new line(alias_t), to.name, from.name
    else
      RBX::AST::Alias.new line(alias_t), to, from
    end
  end

  #
  # Formal arguments
  #

  def args(begin_t, args, end_t, check_args=true)
    line = begin_t ? line(begin_t) : 0
    
    required = args.select { |type, arg| type == :required }.map(&:last)
    optional = args.select { |type, arg| type == :optional }.map(&:last)
    splat    = args.detect { |type, arg| type == :splat    }; splat = splat.last if splat
    post     = args.detect { |type, arg| type == :post     }; post  = post .last if post
    block    = args.detect { |type, arg| type == :block    }; block = block.last if block
    
    if optional.empty?
      optional = nil
    else
      optional.map! { |a| RBX::AST::LocalVariableAssignment.new *a }
      optional = RBX::AST::Block.new line, optional
    end
    
    RBX::AST::FormalArguments19.new line, required, optional, splat, post, block
  end

  def arg(token)
    [:required, value(token).to_sym]
  end

  def optarg(name_t, eql_t, value)
    [:optional, [line(eql_t), value(name_t).to_sym, value]]
  end

  # def optarg(name_t, eql_t, value)
  #   n(:optarg, [ value(name_t).to_sym, value ],
  #     variable_map(name_t).
  #       with_operator(loc(eql_t)).
  #       with_expression(loc(name_t).join(value.loc.expression)))
  # end

  def restarg(star_t, name_t=nil)
    value = name_t ? value(name_t).to_sym : :*
    [:splat, value]
  end

  # def kwarg(name_t)
  #   n(:kwarg, [ value(name_t).to_sym ],
  #     kwarg_map(name_t))
  # end

  # def kwoptarg(name_t, value)
  #   n(:kwoptarg, [ value(name_t).to_sym, value ],
  #     kwarg_map(name_t, value))
  # end

  # def kwrestarg(dstar_t, name_t=nil)
  #   if name_t
  #     n(:kwrestarg, [ value(name_t).to_sym ],
  #       arg_prefix_map(dstar_t, name_t))
  #   else
  #     n0(:kwrestarg,
  #       arg_prefix_map(dstar_t))
  #   end
  # end

  # def shadowarg(name_t)
  #   n(:shadowarg, [ value(name_t).to_sym ],
  #     variable_map(name_t))
  # end

  def blockarg(amper_t, name_t)
    [:block, value(name_t).to_sym]
  end

  #
  # Method calls
  #
  
  def call_method(receiver, dot_t, selector_t,
                  lparen_t=nil, args=[], rparen_t=nil)
    line = receiver ? receiver.line : line(selector_t)
    name = value(selector_t).to_sym
    vcall = receiver.nil?
    receiver = RBX::AST::Self.new line if vcall
    
    if args.empty?
      RBX::AST::Send.new line, receiver, name, vcall
    else
      args = RBX::AST::ArrayLiteral.new line, args
      RBX::AST::SendWithArguments.new line, receiver, name, args, vcall
    end
  end

  # def call_lambda(lambda_t)
  #   n(:send, [ nil, :lambda ],
  #     send_map(nil, nil, lambda_t))
  # end

  def block(method_call, begin_t, args, body, end_t)
    # RBX::AST::Block.new line(begin_t), [body]
    
    method_call.block = RBX::AST::Iter19.new line(begin_t), args, body
    method_call
    
    # _receiver, _selector, *call_args = *method_call

  #   if method_call.type == :yield
  #     diagnostic :error, :block_given_to_yield, nil, method_call.loc.keyword, [loc(begin_t)]
  #   end

  #   last_arg = call_args.last
  #   if last_arg && last_arg.type == :block_pass
  #     diagnostic :error, :block_and_blockarg, nil, last_arg.loc.expression, [loc(begin_t)]
  #   end

  #   if [:send, :super, :zsuper].include?(method_call.type)
  #     n(:block, [ method_call, args, body ],
  #       block_map(method_call.loc.expression, begin_t, end_t))
  #   else
  #     # Code like "return foo 1 do end" is reduced in a weird sequence.
  #     # Here, method_call is actually (return).
  #     actual_send, = *method_call
  #     block =
  #       n(:block, [ actual_send, args, body ],
  #         block_map(actual_send.loc.expression, begin_t, end_t))

  #     n(method_call.type, [ block ],
  #       method_call.loc.with_expression(join_exprs(method_call, block)))
  #   end
  end

  def block_pass(amper_t, arg)
    RBX::AST::BlockPass.new line(amper_t), arg
  end

  def attr_asgn(receiver, dot_t, selector_t)
    RBX::AST::AttributeAssignment.new \
      line(dot_t), receiver, value(selector_t).to_sym, []
  end

  def index(receiver, lbrack_t, indexes, rbrack_t)
    line = line(lbrack_t)
    args = RBX::AST::ArrayLiteral.new line, indexes
    
    RBX::AST::SendWithArguments.new line, receiver, :[], args
  end

  def index_asgn(receiver, lbrack_t, indexes, rbrack_t)
    line = line(lbrack_t)
    args = RBX::AST::ArrayLiteral.new line, indexes
    
    RBX::AST::ElementAssignment.new line, receiver, args
  end

  def binary_op(receiver, operator_t, arg)
    line = receiver.line
    name = value(operator_t).to_sym
    
    RBX::AST::SendWithArguments.new line, receiver, name, arg
  end

  def match_op(receiver, match_t, arg)
    line = receiver.line
    
    if receiver.is_a? RBX::AST::DynamicRegex \
    or receiver.is_a? RBX::AST::RegexLiteral
      RBX::AST::Match2.new line, receiver, arg
    else
      RBX::AST::Match3.new line, arg, receiver
    end
  end

  def unary_op(op_t, receiver)
    method = value(op_t)
    method += '@' if '+'==method or '-'==method
    
    RBX::AST::Send.new line(op_t), receiver, method.to_sym
  end

  def not_op(not_t, begin_t=nil, receiver=nil, end_t=nil)
    # RBX::AST::Not.new line(not_t), receiver
    RBX::AST::Send.new line(not_t), receiver, :'!'
  end

  
  #
  # Control flow
  #
  
  # Logical operations: and, or
  
  def logical_op(type, lhs, op_t, rhs)
    line = line(op_t)
    
    case type
    when :and
      RBX::AST::And.new line, lhs, rhs
    when :or
      RBX::AST::Or.new line, lhs, rhs
    else
      raise 'booooom'
    end
  end
  
  # Conditionals

  def condition(cond_t, cond, then_t, if_true, else_t, if_false, end_t)
    RBX::AST::If.new line(cond_t), check_condition(cond), if_true, if_false
  end
  
  def condition_mod(if_true, if_false, cond_t, cond)
    RBX::AST::If.new line(cond_t), check_condition(cond), if_true, if_false
  end
  
  # def ternary(cond, question_t, if_true, colon_t, if_false)
  #   n(:if, [ check_condition(cond), if_true, if_false ],
  #     ternary_map(cond, question_t, if_true, colon_t, if_false))
  # end

  # # Case matching

  # def when(when_t, patterns, then_t, body)
  #   children = patterns << body
  #   n(:when, children,
  #     keyword_map(when_t, then_t, children, nil))
  # end

  # def case(case_t, expr, when_bodies, else_t, else_body, end_t)
  #   n(:case, [ expr, *(when_bodies << else_body)],
  #     condition_map(case_t, expr, nil, nil, else_t, else_body, end_t))
  # end

  # Loops

  def loop(type, keyword_t, cond, do_t, body, end_t)
    line = line(keyword_t)
    check_first = true
    
    case type
    when :while
      RBX::AST::While.new line, check_condition(cond), body, check_first
    when :until
      RBX::AST::Until.new line, check_condition(cond), body, check_first
    else
      raise "boom a loom #{type}"
    end
  end

  def loop_mod(type, body, keyword_t, cond)
    line = line(keyword_t)
    check_first = !body.is_a?(RBX::AST::Begin)
    
    case type
    when :while
      RBX::AST::While.new line, check_condition(cond), body, check_first
    when :until
      RBX::AST::Until.new line, check_condition(cond), body, check_first
    else
      raise "boom a loom #{type}"
    end
  end

  def for(for_t, iterator, in_t, iteratee, do_t, body, end_t)
    line = line(for_t)
    
    send = RBX::AST::Send.new line, iteratee, :each
    send.block = RBX::AST::For19.new line, iterator, body
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
          if element.is_a?(RBX::AST::SplatValue)
            if (element.instance_variable_get :@sated)
              element = RBX::AST::ArrayLiteral.new line, elements
            end
          else
            element = RBX::AST::ArrayLiteral.new line, elements
          end
        end
        
        element
      else
        x = elements.last
        if x.is_a?(RBX::AST::SplatValue) or x.is_a?(RBX::AST::Send) or x.is_a?(RBX::AST::SendWithArguments)
          rest = elements.pop.value
          array = RBX::AST::ArrayLiteral.new line, elements
          RBX::AST::ConcatArgs.new line, array, rest
        else
          RBX::AST::ArrayLiteral.new line, elements
        end
      end
    
    case type
    when :return
      RBX::AST::Return.new line, value
    when :super
      RBX::AST::Super.new line, value
    when :zsuper
      RBX::AST::ZSuper.new line
    when :defined?
      RBX::AST::Defined.new line, value
    when :yield
      RBX::AST::Yield.new line, value, true
    when :break
      RBX::AST::Break.new line, value
    when :redo
      RBX::AST::Redo.new line
    when :retry
      RBX::AST::Retry.new line
    when :next
      RBX::AST::Next.new line, value
    else
      raise "boom boom boom #{type.inspect}"
    end
  end

  # BEGIN, END

  # def preexe(preexe_t, lbrace_t, compstmt, rbrace_t)
  #   n(:preexe, [ compstmt ],
  #     keyword_map(preexe_t, lbrace_t, [], rbrace_t))
  # end

  def postexe(postexe_t, lbrace_t, compstmt, rbrace_t)
    line = line(postexe_t)
    body = RBX::AST::Block.new line, [compstmt]
    
    node = RBX::AST::Send.new line, RBX::AST::Self.new(line), :at_exit, true
    node.block = RBX::AST::Iter.new line, nil, body
    node
  end

  # Exception handling

  def rescue_body(rescue_t, exc_list, assoc_t, exc_var, then_t, compound_stmt)
    blk = if exc_var
      line = line(assoc_t)
      last_e = RBX::AST::CurrentException.new line
      e_asgn = convert_to_assignment line, exc_var, last_e
      RBX::AST::Block.new compound_stmt.line, [e_asgn, compound_stmt]
    else
      RBX::AST::Block.new compound_stmt.line, [compound_stmt]
    end
    
    RBX::AST::RescueCondition.new line(rescue_t), exc_list, blk, nil
  end

  def begin_body(compound_stmt, rescue_bodies=[],
                 else_t=nil,    else_=nil,
                 ensure_t=nil,  ensure_=nil)
    # if rescue_bodies.any?
    #   if else_t
    #     compound_stmt =
    #     RBX::AST::Rescue.new line(else_t), compound_stmt, rescue_bodies.first, else_
    #       # n(:rescue,
    #       #   [ compound_stmt, *(rescue_bodies + [ else_ ]) ],
    #       #   eh_keyword_map(compound_stmt, nil, rescue_bodies, else_t, else_))
    #   else
    #     compound_stmt =
    #     RBX::AST::Rescue.new line(else_t), compound_stmt, rescue_bodies.first, else_
    #     #   n(:rescue,
    #     #     [ compound_stmt, *(rescue_bodies + [ nil ]) ],
    #     #     eh_keyword_map(compound_stmt, nil, rescue_bodies, nil, nil))
    #   end
    # end
    
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
      compound_stmt = RBX::AST::Rescue.new line(else_t), compound_stmt, first, else_
    end
    
    if ensure_t
      compound_stmt =
        RBX::AST::Ensure.new line(ensure_t), compound_stmt, ensure_
        # n(:ensure,
        #   [ compound_stmt, ensure_ ],
        #   eh_keyword_map(compound_stmt, ensure_t, [ ensure_ ], nil, nil))
    end

    compound_stmt
  end

  
  
  #
  # Expression grouping
  #

  def compstmt(statements)
    case
    when statements.none?
      RBX::AST::NilLiteral.new 0
    when statements.one?
      statements.first
    else
      statements.map! { |s| s.class==RBX::AST::Block ? s.array : s }.flatten!
      RBX::AST::Block.new statements.first.line, statements
    end
  end
  
  def begin(begin_t, body, end_t)
    if body.nil?
      # A nil expression: `()'.
      RBX::AST::NilLiteral.new line(begin_t)
    # elsif body.type == :mlhs  ||
    #      (body.type == :begin &&
    #       body.loc.begin.nil? && body.loc.end.nil?)
    #   # Synthesized (begin) from compstmt "a; b" or (mlhs)
    #   # from multi_lhs "(a, b) = *foo".
    #   n(body.type, body.children,
    #     collection_map(begin_t, body.children, end_t))
    # else
    #   n(:begin, [ body ],
    #     collection_map(begin_t, [ body ], end_t))
    # end
    else
      body
    end
  end
  
  def begin_keyword(begin_t, body, end_t)
    if body.nil?
      # A nil expression: `begin end'.
      raise 'boom1!'
      n0(:kwbegin,
        collection_map(begin_t, nil, end_t))
    # elsif (body.type == :begin &&
    #        body.loc.begin.nil? && body.loc.end.nil?)
    #   raise 'boom2!'
    #   # Synthesized (begin) from compstmt "a; b".
    #   n(:kwbegin, body.children,
    #     collection_map(begin_t, body.children, end_t))
    else
      x = RBX::AST::Begin.new line(begin_t), body
      # p body.to_sexp
      x
    end
  end
  
private
  
  def compose_parts(parts)
    line = parts.first ? parts.first.line : 0
    
    if parts.detect { |part| part.class != RBX::AST::StringLiteral }
      parts.map! do |part|
        if part.class == RBX::AST::StringLiteral
          part
        elsif part.class == RBX::AST::DynamicString
          str = RBX::AST::StringLiteral.new line, part.string
          (part.string.empty? ? [] : [str]) + part.array
        else
          RBX::AST::ToString.new line, part
        end
      end.flatten!
      
      first = parts.shift.string if parts.first.class == RBX::AST::StringLiteral
      first ||= ''
      
      return [true, line, first, [*parts]]
    elsif parts.one?
      return [false, line, parts.first, []]
    else
      string = RBX::AST::StringLiteral.new line, parts.map(&:string).join
      return [false, line, string, []]
    end
  end
  
  def prepare_module_body(line, body)
    if body.is_a?(RBX::AST::NilLiteral)
      nil
    elsif body.is_a?(RBX::AST::Block)
      body
    else
      RBX::AST::Block.new line, [body]
    end
  end
  
  def convert_to_assignment(line, orig, value)
    name = orig.name
    kls  = orig.class
    
    if    kls == RBX::AST::Send
      RBX::AST::LocalVariableAssignment.new line, name, value
    elsif kls == RBX::AST::LocalVariableAccess
      RBX::AST::LocalVariableAssignment.new line, name, value
    elsif kls == RBX::AST::InstanceVariableAccess
      RBX::AST::InstanceVariableAssignment.new line, name, value
    elsif kls == RBX::AST::ClassVariableAccess
      RBX::AST::ClassVariableAssignment.new line, name, value
    elsif kls == RBX::AST::GlobalVariableAccess
      RBX::AST::GlobalVariableAssignment.new line, name, value
    elsif kls == RBX::AST::ConstantAccess
      RBX::AST::ConstantAssignment.new line, name, value
    elsif kls == RBX::AST::ToplevelConstant
      RBX::AST::ConstantAssignment.new line, orig, value
    elsif kls == RBX::AST::ScopedConstant
      RBX::AST::ConstantAssignment.new line, orig, value
    elsif kls == RBX::AST::AttributeAssignment
      orig.arguments = RBX::AST::ActualArguments.new line, value
      orig
    elsif kls == RBX::AST::ElementAssignment
      orig.arguments.array << value
      orig
    else
      binding.pry
      raise 'bomb!'
    end
  end
  
  def check_condition(cond)
    # case cond
    # when :masgn
    #   diagnostic :error, :masgn_as_condition, nil, cond.loc.expression

    # when :begin
    #   if cond.children.count == 1
    #     cond.updated(nil, [
    #       check_condition(cond.children.last)
    #     ])
    #   else
    #     cond
    #   end

    # when :and, :or, :irange, :erange
    #   lhs, rhs = *cond

    #   type = case cond.type
    #   when :irange then :iflipflop
    #   when :erange then :eflipflop
    #   end

    #   if [:and, :or].include?(cond.type) &&
    #          @parser.version == 18
    #     cond
    #   else
    #     cond.updated(type, [
    #       check_condition(lhs),
    #       check_condition(rhs)
    #     ])
    #   end

    kls = cond.class
    
    if    kls == RBX::AST::RegexLiteral
      RBX::AST::Match.new cond.line, cond.source, cond.options
    elsif kls == RBX::AST::Range
      RBX::AST::Flip2.new cond.line, cond.start, cond.finish
    elsif kls == RBX::AST::RangeExclude
      RBX::AST::Flip3.new cond.line, cond.start, cond.finish
    else
      cond
    end
  end

  def line(token)
    token ? loc(token).line : 0
  end
  
  instance_methods.each do |sym|
    deco sym do |*args, &block|
      begin
        # p sym
        deco_super *args, &block
      rescue Exception=>e
        p sym
        puts; p e
        puts; e.backtrace.each { |line| puts line }
        puts
        raise e
      end
    end
  end
  
end


# class RBX::AST::OpAssign1
#   class << self
#     deco :new do |*args|
#       p args
#       deco_super *args
#     end
#   end
# end


class String
  def to_sexp
    pr = Parser::CurrentRuby.new RubiniusBuilder.new

    buffer = Parser::Source::Buffer.new('(string)')
    buffer.source = self
    
    node = pr.parse buffer
    # p node
    node.to_sexp
  end
end

class << Object.new
  class << self
    def parse str, &block
      puts "      : #{str}"
      puts "expect: #{block.call.inspect}"
      puts "actual: #{str.to_sexp.inspect}"
    end
  end

end
