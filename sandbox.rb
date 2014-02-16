
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
  
  # def __LINE__(__LINE__t) end
  
  # # Strings
  
  def string(token)
    RBX::AST::StringLiteral.new line(token), value(token)
  end
  
  def string_internal(token)
    string(token)
  end
  
  def string_compose(begin_t, parts, end_t)
    line = parts.first.line
    
    # if parts.one?
    #   parts.first
    # else
      if parts.detect { |part| !part.is_a? RBX::AST::StringLiteral }
        first = parts.shift.string if parts.first.is_a? RBX::AST::StringLiteral
        first ||= ''
        
        parts.map! do |part|
          if part.is_a? RBX::AST::StringLiteral
            part
          else
            RBX::AST::ToString.new line, part
          end
        end
        
        RBX::AST::DynamicString.new line, first, [*parts]
      elsif parts.one?
        parts.first
      else
        value = parts.map(&:string).join
        RBX::AST::StringLiteral.new line, value
      end
    # end
  end
  
  # def character(char_t)
  #   n(:str, [ value(char_t) ],
  #     prefix_string_map(char_t))
  # end
  
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
    line = parts.first.line
    
    if parts.one?
      str = parts.first
      
      RBX::AST::SymbolLiteral.new line, str.string.to_sym
    else
      if parts.detect { |part| !part.is_a? RBX::AST::StringLiteral }
        first = parts.shift.string if parts.first.is_a? RBX::AST::StringLiteral
        first ||= ''
        
        parts.map! do |part|
          if part.is_a? RBX::AST::StringLiteral
            part
          else
            RBX::AST::ToString.new line, part
          end
        end
        
        RBX::AST::DynamicSymbol.new line, first, [*parts]
      else
        value = parts.map(&:string).join
        RBX::AST::SymbolLiteral.new line, value
      end
    end
  end
  
  # Executable strings
  
  # def xstring_compose(begin_t, parts, end_t)
  #   n(:xstr, [ *parts ],
  #     string_map(begin_t, parts, end_t))
  # end
  
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
    
    value(regopt_t).each_char.map { |chr| opt_convert[chr] }.inject(&:+) or 0
  end
  
  def regexp_compose(begin_t, parts, end_t, options)
    line = line(begin_t)
    
    if parts.empty?
      RBX::AST::RegexLiteral.new line, '', options
    elsif parts.one?
      str = parts.first
      
      RBX::AST::RegexLiteral.new line, str.string, options
    else
      raise 'boom'
      # if parts.detect { |part| !part.is_a? RBX::AST::StringLiteral }
      #   first = parts.shift.string if parts.first.is_a? RBX::AST::StringLiteral
      #   first ||= ''
        
      #   parts.map! do |part|
      #     if part.is_a? RBX::AST::StringLiteral
      #       part
      #     else
      #       RBX::AST::ToString.new line, part
      #     end
      #   end
        
      #   RBX::AST::DynamicSymbol.new line, first, [*parts]
      # else
      #   value = parts.map(&:string).join
      #   RBX::AST::SymbolLiteral.new line, value
      # end
    end
  end
  
  
  # Arrays

  def array(begin_t, elements, end_t)
    line = line(begin_t)
    
    if elements.detect { |x| x.is_a? RBX::AST::SplatValue}
      if elements.one?
        elements.first
      else
        rest = elements.pop.value
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

  # def self(token)
  #   n0(:self,
  #     token_map(token))
  # end

  def ident(token)
    # RBX::AST::LocalVariableAccess.new line(token), value(token).to_sym
    receiver = RBX::AST::Self.new line(token)
    RBX::AST::Send.new line(token), nil, value(token).to_sym, true
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

  # def back_ref(token)
  #   n(:back_ref, [ value(token).to_sym ],
  #     token_map(token))
  # end

  # def nth_ref(token)
  #   n(:nth_ref, [ value(token) ],
  #     token_map(token))
  # end
  
  def accessible(node)
    node
  end
  
  def const(token)
    RBX::AST::ConstantAccess.new line(token), value(token).to_sym
  end

  def const_global(t_colon3, token)
    line = line(token)
    name = value(token).to_sym
    
    RBX::AST::ToplevelConstant.new line, name
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
    node
  end

  # def const_op_assignable(node)
  #   node.updated(:casgn)
  # end

  def assign(lhs, eql_t, rhs)
    line = line(eql_t)
    name = lhs.name
    
    case lhs
    when RBX::AST::Send
      RBX::AST::LocalVariableAssignment.new line, name, rhs
    when RBX::AST::LocalVariableAccess
      RBX::AST::LocalVariableAssignment.new line, name, rhs
    when RBX::AST::InstanceVariableAccess
      RBX::AST::InstanceVariableAssignment.new line, name, rhs
    when RBX::AST::GlobalVariableAccess
      RBX::AST::GlobalVariableAssignment.new line, name, rhs
    else
      # binding.pry
      raise 'bomb!'
    end
  end

  def op_assign(lhs, op_t, rhs)
    line = lhs.line
    name = value(op_t).to_sym
    send = RBX::AST::SendWithArguments.new line, lhs, name, rhs
    
    RBX::AST::LocalVariableAssignment.new line, lhs.name, send
    
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
  
  # def def_class(class_t, name, lt_t, superclass, body, end_t)
  #   n(:class, [ name, superclass, body ],
  #     module_definition_map(class_t, name, lt_t, end_t))
  # end
  
  # def def_sclass(class_t, lshft_t, expr, body, end_t)
  #   n(:sclass, [ expr, body ],
  #     module_definition_map(class_t, nil, lshft_t, end_t))
  # end
  
  def def_module(module_t, name, body, end_t)
    line = line(module_t)
    name = name.name if name.is_a? RBX::AST::ConstantAccess
    body = RBX::AST::Block.new line, [body] unless body.is_a? RBX::AST::Block
    
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

  # def def_singleton(def_t, definee, dot_t,
  #                   name_t, args,
  #                   body, end_t)
  #   case definee.type
  #   when :int, :str, :dstr, :sym, :dsym,
  #        :regexp, :array, :hash

  #     diagnostic :error, :singleton_literal, nil, definee.loc.expression

  #   else
  #     n(:defs, [ definee, value(name_t).to_sym, args, body ],
  #       definition_map(def_t, dot_t, name_t, end_t))
  #   end
  # end

  # def undef_method(undef_t, names)
  #   n(:undef, [ *names ],
  #     keyword_map(undef_t, nil, names, nil))
  # end

  # def alias(alias_t, to, from)
  #   n(:alias, [ to, from ],
  #     keyword_map(alias_t, nil, [to, from], nil))
  # end

  #
  # Formal arguments
  #

  def args(begin_t, args, end_t, check_args=true)
    line = begin_t ? line(begin_t) : 0
    # RBX::AST::FormalArguments19.new line, required, optional, splat, post, block
    RBX::AST::FormalArguments19.new line, args, nil, nil, nil, nil
  end

  # def arg(name_t)
  #   n(:arg, [ value(name_t).to_sym ],
  #     variable_map(name_t))
  # end

  # def optarg(name_t, eql_t, value)
  #   n(:optarg, [ value(name_t).to_sym, value ],
  #     variable_map(name_t).
  #       with_operator(loc(eql_t)).
  #       with_expression(loc(name_t).join(value.loc.expression)))
  # end

  # def restarg(star_t, name_t=nil)
  #   if name_t
  #     n(:restarg, [ value(name_t).to_sym ],
  #       arg_prefix_map(star_t, name_t))
  #   else
  #     n0(:restarg,
  #       arg_prefix_map(star_t))
  #   end
  # end

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

  # def blockarg(amper_t, name_t)
  #   n(:blockarg, [ value(name_t).to_sym ],
  #     arg_prefix_map(amper_t, name_t))
  # end

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

  # def block(method_call, begin_t, args, body, end_t)
  #   _receiver, _selector, *call_args = *method_call

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
  # end

  # def block_pass(amper_t, arg)
  #   n(:block_pass, [ arg ],
  #     unary_op_map(amper_t, arg))
  # end

  # def attr_asgn(receiver, dot_t, selector_t)
  #   method_name = (value(selector_t) + '=').to_sym

  #   # Incomplete method call.
  #   n(:send, [ receiver, method_name ],
  #     send_map(receiver, dot_t, selector_t))
  # end

  # def index(receiver, lbrack_t, indexes, rbrack_t)
  #   n(:send, [ receiver, :[], *indexes ],
  #     send_index_map(receiver, lbrack_t, rbrack_t))
  # end

  # def index_asgn(receiver, lbrack_t, indexes, rbrack_t)
  #   # Incomplete method call.
  #   n(:send, [ receiver, :[]=, *indexes ],
  #     send_index_map(receiver, lbrack_t, rbrack_t))
  # end

  def binary_op(receiver, operator_t, arg)
    line = receiver.line
    name = value(operator_t).to_sym
    
    RBX::AST::SendWithArguments.new line, receiver, name, arg
  end

  # def match_op(receiver, match_t, arg)
  #   source_map = send_binary_op_map(receiver, match_t, arg)

  #   if receiver.type == :regexp &&
  #         receiver.children.count == 2 &&
  #         receiver.children.first.type == :str

  #     str_node, opt_node = *receiver
  #     regexp_body, = *str_node
  #     *regexp_opt  = *opt_node

  #     if defined?(Encoding)
  #       regexp_body = case
  #       when regexp_opt.include?(:u)
  #         regexp_body.encode(Encoding::UTF_8)
  #       when regexp_opt.include?(:e)
  #         regexp_body.encode(Encoding::EUC_JP)
  #       when regexp_opt.include?(:s)
  #         regexp_body.encode(Encoding::WINDOWS_31J)
  #       when regexp_opt.include?(:n)
  #         regexp_body.encode(Encoding::BINARY)
  #       else
  #         regexp_body
  #       end
  #     end

  #     Regexp.new(regexp_body).names.each do |name|
  #       @parser.static_env.declare(name)
  #     end

  #     n(:match_with_lvasgn, [ receiver, arg ],
  #       source_map)
  #   else
  #     n(:send, [ receiver, :=~, arg ],
  #       source_map)
  #   end
  # end

  # def unary_op(op_t, receiver)
  #   case value(op_t)
  #   when '+', '-'
  #     method = value(op_t) + '@'
  #   else
  #     method = value(op_t)
  #   end

  #   n(:send, [ receiver, method.to_sym ],
  #     send_unary_op_map(op_t, receiver))
  # end

  # def not_op(not_t, begin_t=nil, receiver=nil, end_t=nil)
  #   if @parser.version == 18
  #     n(:not, [ receiver ],
  #       unary_op_map(not_t, receiver))
  #   else
  #     if receiver.nil?
  #       nil_node = n0(:begin, collection_map(begin_t, nil, end_t))

  #       n(:send, [
  #         nil_node, :'!'
  #       ], send_unary_op_map(not_t, nil_node))
  #     else
  #       n(:send, [ receiver, :'!' ],
  #         send_unary_op_map(not_t, receiver))
  #     end
  #   end
  # end

  
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

  # def condition(cond_t, cond, then_t,
  #               if_true, else_t, if_false, end_t)
  #   n(:if, [ check_condition(cond), if_true, if_false ],
  #     condition_map(cond_t, cond, then_t, if_true, else_t, if_false, end_t))
  # end
  
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

  # # Loops

  # def loop(type, keyword_t, cond, do_t, body, end_t)
  #   n(type, [ check_condition(cond), body ],
  #     keyword_map(keyword_t, do_t, nil, end_t))
  # end

  # def loop_mod(type, body, keyword_t, cond)
  #   if body.type == :kwbegin
  #     type = :"#{type}_post"
  #   end

  #   n(type, [ check_condition(cond), body ],
  #     keyword_mod_map(body, keyword_t, cond))
  # end

  # def for(for_t, iterator, in_t, iteratee,
  #         do_t, body, end_t)
  #   n(:for, [ iterator, iteratee, body ],
  #     for_map(for_t, in_t, do_t, end_t))
  # end

  # # Keywords

  # def keyword_cmd(type, keyword_t, lparen_t=nil, args=[], rparen_t=nil)
  #   if type == :yield && args.count > 0
  #     last_arg = args.last
  #     if last_arg.type == :block_pass
  #       diagnostic :error, :block_given_to_yield, nil, loc(keyword_t), [last_arg.loc.expression]
  #     end
  #   end

  #   n(type, args,
  #     keyword_map(keyword_t, lparen_t, args, rparen_t))
  # end

  # # BEGIN, END

  # def preexe(preexe_t, lbrace_t, compstmt, rbrace_t)
  #   n(:preexe, [ compstmt ],
  #     keyword_map(preexe_t, lbrace_t, [], rbrace_t))
  # end

  # def postexe(postexe_t, lbrace_t, compstmt, rbrace_t)
  #   n(:postexe, [ compstmt ],
  #     keyword_map(postexe_t, lbrace_t, [], rbrace_t))
  # end

  # # Exception handling

  # def rescue_body(rescue_t,
  #                 exc_list, assoc_t, exc_var,
  #                 then_t, compound_stmt)
  #   n(:resbody, [ exc_list, exc_var, compound_stmt ],
  #     rescue_body_map(rescue_t, exc_list, assoc_t,
  #                     exc_var, then_t, compound_stmt))
  # end

  # def begin_body(compound_stmt, rescue_bodies=[],
  #                else_t=nil,    else_=nil,
  #                ensure_t=nil,  ensure_=nil)
  #   if rescue_bodies.any?
  #     if else_t
  #       compound_stmt =
  #         n(:rescue,
  #           [ compound_stmt, *(rescue_bodies + [ else_ ]) ],
  #           eh_keyword_map(compound_stmt, nil, rescue_bodies, else_t, else_))
  #     else
  #       compound_stmt =
  #         n(:rescue,
  #           [ compound_stmt, *(rescue_bodies + [ nil ]) ],
  #           eh_keyword_map(compound_stmt, nil, rescue_bodies, nil, nil))
  #     end
  #   end

  #   if ensure_t
  #     compound_stmt =
  #       n(:ensure,
  #         [ compound_stmt, ensure_ ],
  #         eh_keyword_map(compound_stmt, ensure_t, [ ensure_ ], nil, nil))
  #   end

  #   compound_stmt
  # end

  
  
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
  
  # def begin_keyword(begin_t, body, end_t)
  #   if body.nil?
  #     # A nil expression: `begin end'.
  #     n0(:kwbegin,
  #       collection_map(begin_t, nil, end_t))
  #   elsif (body.type == :begin &&
  #          body.loc.begin.nil? && body.loc.end.nil?)
  #     # Synthesized (begin) from compstmt "a; b".
  #     n(:kwbegin, body.children,
  #       collection_map(begin_t, body.children, end_t))
  #   else
  #     n(:kwbegin, [ body ],
  #       collection_map(begin_t, [ body ], end_t))
  #   end
  # end
  
private
  
  def check_condition(cond)
    case cond
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

    when RBX::AST::RegexLiteral
      RBX::AST::Match.new cond.line, cond.source, cond.options
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


# class RBX::AST::Module
#   class << self
#     def new *args
#       p args
#       deco_super
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
      p str.to_sexp
      p block.call
    end
  end
  
end
