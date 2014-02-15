
require 'deco'

require 'rubinius/toolset'
require 'rubinius/compiler'
require 'rubinius/ast'

require 'parser/current'

RBX = Rubinius::ToolSet.current::TS

# module RBX; end
# module RBX::AST; end

class RBX::AST::Node
  # def inspect
  #   to_sexp
  # end
end

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
  
  # def negate(uminus_t, numeric) end
  
  # def __LINE__(__LINE__t) end
  
  # # Strings
  
  # def string(token)
  #   RBX::AST::StringLiteral.new line(token), value(token)
  # end
  
  # def string_internal(token)
  #   RBX::AST::StringLiteral.new line(token), value(token)
  # end
  
  # def string_compose(begin_t, parts, end_t)
  #   p [begin_t, parts, end_t]
  #   parts.first
  #   require 'pry'
  #   binding.pry
  #   # # AST::DynamicString.new line, str, array
  #   if parts.one?
  #     # RBX::AST::StringLiteral.new line, str, array
  #     if begin_t.nil? && end_t.nil?
  #       parts.first
  #     else
  #       raise 'booom!'
  #       n(:str, parts.first.children,
  #         string_map(begin_t, parts, end_t))
  #     end
  #   else
  #     RBX::AST::DynamicString.new line, str, [*parts]
  #     # raise 'wooomba'
  #   #   n(:dstr, [ *parts ],
  #   #     string_map(begin_t, parts, end_t))
  #   end
  # end
  
  #   # def process_dstr(line, str, array)
  #   #   AST::DynamicString.new line, str, array
  #   # end
  # # def character(char_t)
  # #   n(:str, [ value(char_t) ],
  # #     prefix_string_map(char_t))
  # # end
  
  # # def __FILE__(__FILE__t) end
  
  def accessible(node)
    node
  end
  
private
  
  def line(token)
    loc(token).line
  end
  
  instance_methods.each do |sym|
    deco sym do |*args, &block|
      begin
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


class String
  def to_sexp
    pr = Parser::CurrentRuby.new RubiniusBuilder.new

    buffer = Parser::Source::Buffer.new('(string)')
    buffer.source = self
    
    node = pr.parse buffer
    node.to_sexp
  end
end
