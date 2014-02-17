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
  `mspec spec -G fails -f s`
  # sh "mspec spec/true_spec.rb"
end

task :sandbox do
  require_relative 'sandbox.rb'
end

task :default => :spec
# task :default => :sandbox
