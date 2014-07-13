#!/usr/bin/env rake
# require "bundler/gem_tasks"
require "redcard"

# if RedCard.check :rubinius
#   namespace :spec do
#     desc "Load the parser into the Spec ToolSet"
#     task :toolset do
#       Rubinius::ToolSet.start
#       require_relative "sandbox.rb"
#       Rubinius::ToolSet.finish :spec
#     end
#   end

#   dependencies = %w[spec:toolset]
# else
  dependencies = []
# end

desc "Run the specs"
task :spec => dependencies do
  # exec "mspec spec -G fails"
  sh "mspec -I #{File.dirname __FILE__} -r spec/spec_helper spec -G fails"
end

task :sandbox do
  $SANDBOX_VERBOSE = true
  
  require_relative 'sandbox.rb'
  
  def parse str, &block
    actual = str.to_sexp
    puts "      : #{str}"
    puts "expect: #{block.call.inspect}"
    puts "actual: #{actual.inspect}"
    puts block.call == actual ? "PASS" : "FAIL"
  end
end

task :default => :spec
# task :default => :sandbox
