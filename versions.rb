#!/usr/bin/env ruby

require File.expand_path('../ruby_version', __FILE__)

installed_rubies = `rbenv versions --bare`.lines.collect(&:strip)
installed_ruby_versions = installed_rubies.map {|v| RubyVersion.parse v }.group_by(&:implementation_version)

available_rubies = `rbenv install -l`.lines.map(&:strip)[1..-1]
available_ruby_versions = available_rubies.map {|v| RubyVersion.parse v }.group_by(&:implementation_version)

ruby_versions_info = installed_ruby_versions.inject({}) do |latest, implementation_info|
  latest[implementation_info[0]] ={installed: implementation_info[1].max, available: available_ruby_versions[implementation_info[0]].max}
  latest
end


require 'yaml'

info = {
  # "description" => RUBY_DESCRIPTION,
  "rubies" => ruby_versions_info,
  "ruby-build" => `ruby-build --version`.strip,
  "rbenv" => `rbenv --version`.strip,
  "brew" => `brew --version`.strip,
}

puts info.to_yaml

