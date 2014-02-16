
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
    
    if parts.one?
      parts.first
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
        
        RBX::AST::DynamicString.new line, first, [*parts]
      else
        value = parts.map(&:string).join
        RBX::AST::StringLiteral.new line, value
      end
    end
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
  
  
  
  #
  # Method calls
  #
  
  def call_method(receiver, dot_t, selector_t,
                  lparen_t=nil, args=[], rparen_t=nil)
    line = receiver.line
    name = value(selector_t).to_sym
    
    if args.empty?
      RBX::AST::Send.new line, receiver, name
    else
      args = RBX::AST::ArrayLiteral.new line, args
      RBX::AST::SendWithArguments.new line, receiver, name, args
      # require 'pry'
      # binding.pry
      # x
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

  # #
  # # Access
  # #

  # def self(token)
  #   n0(:self,
  #     token_map(token))
  # end

  def ident(token)
    # RBX::AST::LocalVariableAccess.new line(token), value(token).to_sym
    receiver = RBX::AST::Self.new line(token)
    RBX::AST::Send.new line(token), nil, value(token).to_sym, true
  end

  # def ivar(token)
  #   n(:ivar, [ value(token).to_sym ],
  #     variable_map(token))
  # end

  # def gvar(token)
  #   n(:gvar, [ value(token).to_sym ],
  #     variable_map(token))
  # end

  # def cvar(token)
  #   n(:cvar, [ value(token).to_sym ],
  #     variable_map(token))
  # end

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
  
  # def const(name_t)
  #   n(:const, [ nil, value(name_t).to_sym ],
  #     constant_map(nil, nil, name_t))
  # end

  # def const_global(t_colon3, name_t)
  #   cbase = n0(:cbase, token_map(t_colon3))

  #   n(:const, [ cbase, value(name_t).to_sym ],
  #     constant_map(cbase, t_colon3, name_t))
  # end

  # def const_fetch(scope, t_colon2, name_t)
  #   n(:const, [ scope, value(name_t).to_sym ],
  #     constant_map(scope, t_colon2, name_t))
  # end

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

  # def assign(lhs, eql_t, rhs)
  #   (lhs << rhs).updated(nil, nil,
  #     :location => lhs.loc.
  #       with_operator(loc(eql_t)).
  #       with_expression(join_exprs(lhs, rhs)))
  # end

  def op_assign(lhs, op_t, rhs)
    # require 'pry'
    # binding.pry
    # p [lhs_t.to_sexp, op_t, rhs.to_sexp]
    
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
    loc(token).line
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
      end
    end
  end
  
end


# class RBX::AST::SendWithArguments
#   def self.new *args
#     p args
#   end
# end


class String
  def to_sexp
    pr = Parser::CurrentRuby.new RubiniusBuilder.new

    buffer = Parser::Source::Buffer.new('(string)')
    buffer.source = self
    
    node = pr.parse buffer
    # p node.class
    node.to_sexp
  end
end

    # p "1 if /x/".to_sexp
    # p [:if, [:match, [:regex, "x", 0]], [:lit, 1], nil]
    