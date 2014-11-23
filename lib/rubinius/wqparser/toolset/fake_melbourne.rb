
class CodeTools::FakeMelbourne < CodeTools::Melbourne
  def string_to_ast string, file, line
    file ||= "(eval)"
    line ||= 1
    @parser ||= ::Parser::CurrentRuby.new Rubinius::ToolSets::WQParser::Processor.new
    buffer = ::Parser::Source::Buffer.new file, line
    buffer.source = string
    @parser.parse buffer
  end
  
  def file_to_ast file, line
    string = File.read file
    string_to_ast string, file, line
  end
end
