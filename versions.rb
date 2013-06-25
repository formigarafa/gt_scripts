#!/usr/bin/env ruby

require File.expand_path('../ruby_version', __FILE__)

Status = {
  alert: 0x2757.chr('UTF-8'),
  tick: 0x2705.chr('UTF-8')
}

installed_rubies = `rbenv versions --bare`.lines.collect(&:strip)
installed_ruby_versions = installed_rubies.map {|v| RubyVersion.parse v }.group_by(&:implementation_version)

available_rubies = `rbenv install -l`.lines.map(&:strip)[1..-1]
available_ruby_versions = available_rubies.map {|v| RubyVersion.parse v }.group_by(&:implementation_version)

ruby_versions_info = installed_ruby_versions.inject({}) do |latest, implementation_info|
  latest_installed = implementation_info[1].max
  latest_available = available_ruby_versions[implementation_info[0]].max

  latest[implementation_info[0]] = {
    installed: implementation_info[1].max, 
    available: available_ruby_versions[implementation_info[0]].max,
    status: latest_available > latest_installed ? :alert : :tick
  }
  latest
end

require 'yaml'

info = {
  # "description" => RUBY_DESCRIPTION,
  "testar" => ["brew outdated"],
  "rubies" => ruby_versions_info,
  "ruby-build" => `ruby-build --version`.strip,
  "rbenv" => `rbenv --version`.strip,
  "brew" => `brew --version`.strip,
}

info["rubies"].each do |k, v|
  description = if v[:status] == :tick
    v[:installed].release
  else
    "#{v[:installed].release} < #{v[:available].release}"
  end

  puts "#{Status[v[:status]]} #{v[:installed].implementation_version}: #{description}"
end

info.delete "rubies"

puts info.to_yaml
