class RubyVersion
  include Comparable

  attr_accessor :implementation, :version, :dev, :preview, :rc, :patch_level, :timestamp, :semantic
  # attr_accessor :match_data, :src_string


  def initialize(version_info = {})
    self.implementation = version_info[:implementation]
    self.version = version_info[:version].to_s.split(".").map(&:to_i)
    self.dev = version_info[:dev]
    self.preview = version_info[:preview]
    self.rc = version_info[:rc]
    self.patch_level = version_info[:patch_level]
    self.timestamp = version_info[:timestamp]

    # http://www.ruby-lang.org/en/news/2013/12/21/semantic-versioning-after-2-1-0/
    self.semantic = implementation.nil? && (version[0] > 2 || (version[0] == 2 && version[1] >= 1))
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
    if semantic
      return version[0].to_s
    end

    joint_version = version.any? && version.join(".") || nil
    [implementation, joint_version].compact.join "-"
  end

  def release
    [timestamp, patch_level, rc, preview, dev].compact.first
  end

  def final_release?
    [dev, preview, rc].none?
  end

  # def inspect
  #   {implementation: implementation_version, timestamp: timestamp, patch_level: patch_level, rc: rc, preview: preview, dev: dev}
  # end

  def to_s
    if semantic
      joint_version = version.any? && version.join(".") || nil
      semantic_implementation_version = [implementation, joint_version].compact.join "-"
      [semantic_implementation_version, release].compact.join("-")
    else
      [implementation_version, release].compact.join("-")
    end
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
