#!/usr/bin/env ruby

class RubyVersion
  include Comparable

  attr_accessor :implementation, :version, :dev, :preview, :rc, :patch_level, :timestamp
  # attr_accessor :match_data, :src_string


  def initialize(version_info = {})
    self.implementation = version_info[:implementation]
    self.version = version_info[:version].to_s.split(".").map(&:to_i)
    self.dev = version_info[:dev]
    self.preview = version_info[:preview]
    self.rc = version_info[:rc]
    self.patch_level = version_info[:patch_level]
    self.timestamp = version_info[:timestamp]
  end

  def self.parse(version_string)
    version_string_components = version_string.split "-"
    version_info = {}
    
    if version_string_components[0].match %r{^([0-9]+(\.[0-9]+)+)$}
      version_info[:implementation] = nil # mri
      version_info[:version] = version_string_components[0]
      release = version_string_components[1]
    elsif version_string_components[1].match %r{^([0-9]+(\.[0-9]+)+)$}
      version_info[:implementation] = version_string_components[0]
      version_info[:version] = version_string_components[1]
      release = version_string_components[2]
    else
      version_info[:implementation] = version_string_components[0]
      release = version_string_components[1]
    end

    # puts version_string_components.inspect

    match_data = release.to_s.match(
      %r{^
        (
          (dev)
          |
          (preview[0-9]+)
          |
          (rc[0-9]+)
          |
          (p[0-9]+)
          |
          ([0-9]{4}\.[0-9]{2})
        )
      $}x
    )

    if match_data
      version_info[:dev] = match_data[2]
      version_info[:preview] = match_data[3]
      version_info[:rc] = match_data[4]
      version_info[:patch_level] = match_data[5]
      version_info[:timestamp] = match_data[6]
    end
    version = new version_info
    # version.src_string = version_string
    # version.match_data = match_data
    version
  end

  def implementation_version
    joint_version = version.any? && version.join(".") || nil
    [implementation, joint_version].compact.join "-"
  end

  def release
    [timestamp, patch_level, rc, preview, dev].compact.first
  end

  # def inspect
  #   {implementation: implementation_version, timestamp: timestamp, patch_level: patch_level, rc: rc, preview: preview, dev: dev}
  # end

  def to_s
    [implementation_version, release].compact.join("-")
  end


  def to_yaml( opts = {} )
    YAML::quick_emit( self, opts ) do |out|
      out.map( taguri, to_yaml_style ) do |map|
        map.add('data', to_s)
      end
    end
  end

  protected
  def <=>(other_ruby_version)
    comparable_array <=> other_ruby_version.comparable_array
  end

  def comparable_array
    [implementation.to_s, version, timestamp.to_s, patch_level.to_s, (dev ? -1: 0), (preview ? -1: 0), preview.to_s, (rc ? -1: 0), rc.to_s]
  end
end


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


# require 'pry'
# binding.pry

