#!/usr/bin/env ruby

require File.expand_path('../ruby_version', __FILE__)

Status = {
  alert: 0x2757.chr('UTF-8'),
  tick: 0x2705.chr('UTF-8')
}


installed_rubies_and_aliases = `rbenv versions --bare`.lines.collect(&:strip)
installed_ruby_aliases = `rbenv alias --list 2> /dev/null`.lines.collect(&:strip).collect{|r_alias| r_alias.split(' => ')[0]}
installed_rubies = installed_rubies_and_aliases - installed_ruby_aliases

installed_ruby_versions = installed_rubies.map {|v| RubyVersion.parse v }.group_by(&:implementation_version)

available_rubies = `rbenv install -l`.lines.map(&:strip)[1..-1]
available_ruby_versions = available_rubies.map {|v| RubyVersion.parse v }
available_final_ruby_release_versions = available_ruby_versions.select{|v| v.final_release? }
grouped_availavble_ruby_versions = available_final_ruby_release_versions.group_by(&:implementation_version)

ruby_versions_info = installed_ruby_versions.inject({}) do |latest, implementation_info|
  latest_installed = implementation_info[1].max
  latest_available = grouped_availavble_ruby_versions[implementation_info[0]].max

  latest[implementation_info[0]] = {
    installed: implementation_info[1].max, 
    available: grouped_availavble_ruby_versions[implementation_info[0]].max,
    status: latest_available > latest_installed ? :alert : :tick
  }
  latest
end

require 'yaml'

info = {
  # "description" => RUBY_DESCRIPTION,
  "brew_outdated" => `brew outdated`.lines.map(&:strip),
  "brew_version" => `brew --version`.strip,
  "rubies" => ruby_versions_info,
  "ruby-build" => `ruby-build --version`.strip,
  "rbenv" => `rbenv --version`.strip,
  "Updated at" => Time.now.asctime
}

info["rubies"].each do |k, v|
  description = if v[:status] == :tick
    v[:installed].release
  else
    if v[:installed].semantic
      "#{v[:installed]} < #{v[:available]}"
    else
      "#{v[:installed].release} < #{v[:available].release}"
    end
  end

  if v[:installed].semantic
    puts "#{Status[v[:status]]} #{v[:installed]}: #{description}"
  else
    puts "#{Status[v[:status]]} #{v[:installed].implementation_version}: #{description}"
  end
end

info.delete "rubies"

puts "---"

# info["brew_outdated"] = `brew outdated`.lines.map(&:strip)
if info["brew_outdated"].any?
  puts "#{info["brew_version"]}: brew"
  info["brew_outdated"].each do |formula|
    puts "#{Status[:alert]} #{formula} is outdated"
  end
else
  puts "#{Status[:tick]} #{info["brew_version"]}: brew is up to date"
end
info.delete "brew_outdated"
info.delete "brew_version"

puts info.to_yaml
