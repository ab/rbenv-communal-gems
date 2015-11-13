#!/usr/bin/env ruby
#
# Syncs Ruby binstubs for ruby-communal-gems.
# Run this everytime you install a new Ruby, or when you install a new gem
# with a bin/ command. (ie, when you typically do rbenv rehash)
#
# See: https://github.com/tpope/rbenv-communal-gems/issues/5
#
require 'fileutils'

versions_path = File.expand_path('~/.rbenv/versions')
prefixes = %w[2.0.0-* 2.1.* 1.9.* 2.2.*]
debug = ARGV.include?('-d') || ARGV.include?('--debug')
puts "(running in simulation mode)" if debug

prefixes.each do |prefix|
  # { 'pry' => '/path/to/pry', ... }
  bins = Dir["#{versions_path}/#{prefix}/bin/*"].inject({}) do |hash, bin|
    base = File.basename(bin)
    hash[base] = bin unless %w[gem ruby irb ri rdoc erb testrb].include?(base)
    hash
  end

  Dir["#{versions_path}/#{prefix}"].each do |ver|
    bins.each do |bin, path|
      target = ver+'/bin/'+bin

      unless File.exists?(target)
        puts '+ '+target
        FileUtils.cp path, target  unless debug
      end
    end
  end
end
