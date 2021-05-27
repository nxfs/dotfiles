require 'json'
require 'ostruct'

# Given a base and a pattern, expand the base to include the first dir
# matched by the pattern. If opt must_single_match is true this will only
# happen if there is only one match. If no expansion could be done, then
# return nil.
def expand base, pattern, opts={}
  must_single_match = opts.fetch :must_single_match, false

  dirs = dirs_matching(File.join(base, "*")).select do |dir|
    File.basename(dir) =~ pattern
  end

  return dirs.first if !must_single_match || dirs.length == 1

  nil
end

def dirs_matching path
  Dir[path].sort.select {|dir| File.directory? dir}
end

# Turn a pattern (string of the form "/.../") or a prefix (normal string) into a
# pattern that will match as expected in a insensitive way.
def resolve pattern_or_prefix
  pattern = if pattern? pattern_or_prefix
    Regexp.new pattern_or_prefix[1..-2], "i"
  else
    /^#{pattern_or_prefix}/i
  end
end

def pattern? pattern_or_prefix
  pattern_or_prefix.start_with?("/") && pattern_or_prefix.end_with?("/")
end

# Given a list where the first is a base and the rest are patterns or prefixes,
# attempt to successively expand as many as possible. So, if we have the
# following directory structure:
#   base/we/were/here/when/we/wrote/this
# and the following list:
#   [base, w, /ere/, src]
# then we will expand to:
#   base/we/were
# The elements of the list will be interpreted in the following way:
#   - "something": prefix
#   - "/something/": pattern (case-insensitive regex)
#   - "": any folder as long as there's only one
#   - ".": first folder, when ordered lexiographically
def reduce_expand list
  expanded = list.reduce do |base, pattern_or_prefix|
    expanded = if pattern_or_prefix == "."
      expand base, /./
    elsif pattern_or_prefix == ""
      expand base, /./, :must_single_match => true
    else
      # first we try, interpreting prefixes as prefixes
      pattern = resolve pattern_or_prefix
      e = expand base, pattern

      # if this failed, then we try with prefixes as patterns
      if e.nil? && !pattern?(pattern_or_prefix)
        pattern = resolve "/#{pattern_or_prefix}/"
        expand base, pattern
      else
        e
      end
    end

    break base unless expanded
    expanded
  end

  expanded if expanded != list.first
end

# For each environment variable VAR, replace any instances
# of $VAR with its value in the given string. This is needed
# because shortcuts are given as strings and need to be treated
# like normal paths, which can use these variables.
def interpolate_env str
  ENV.each do |key, value|
    str = str.gsub(/\$#{key}\b/, value)
  end
  str
end

# Return the shortcuts path that matches, if it exists, otherwise
# return nil.
def shortcut_expand pattern_or_prefix, shortcuts
  if pattern_or_prefix != "."
    pattern = resolve pattern_or_prefix
    match = shortcuts.detect do |name, path|
      name =~ pattern
    end
    interpolate_env(match.last) if match
  end
end

# Return a hash representation of the config.
def load_config
  config = OpenStruct.new(
    :base => "#{ENV["C_TOOL_PROJECT_PATH"]}",
    :initial_auto_expand => true,
    :shortcuts => []
  )

  if File.exists? config_path
    IO.foreach(config_path) do |line|
      next if line =~ /^\s*(\#|$)/

      if line =~ /^\s*initial_auto_expand\s*=\s*(false|0)/
        config.initial_auto_expand = false
      end

      if line =~ /^\s*base\s*=\s*(.+)$/
        config.base = interpolate_env $1
      end

      if line =~ /^\s*(\w+)\s*:\s*(.+)$/
        config.shortcuts << [$1, $2]
      end
    end
  end
  config
end

# Return the string that should be added to a config file when it's created for
# the first time.
def config_help
"# Put your personal config here. Default options are commented out.

# Expansion start from this value
# base=/workplace/$USER

# If true, the first expansion will attempt to cd into src and rails-root
# directories
# initial_auto_expand=true

# Shortcuts can be spacified here. Each must be of the following form:
#   <shortcut name>:<path>
# Shortcuts are given preference over folders, and only apply to the first
# argument given to c.
# home:~
"
end

def config_path
  "#{ENV["C_TOOL_CFG_PATH"]}"
end

# Print out the relevant output.
if first_arg = ARGV.shift
  if first_arg == "touch-config"
    # Create the config file if needed. If created, include the help.
    unless File.exists? config_path
      IO.binwrite(config_path, config_help)
    end
  elsif first_arg == "list"
    # List all the shortcuts and directories that can be used.
    config = load_config
    list = "Shortcuts:"
    config.shortcuts.each {|n,p| list += "\n #{n} -> #{p}"}
    list += "\n\nDirectories in #{config.base}:\n "
    list += dirs_matching(File.join(config.base, "*")).map {|d| File.basename d}.sort.join("\n ")
    puts list
  else
    # Attempt to expand the path based on the input.
    config = load_config

    result = if from_shortcut = shortcut_expand(first_arg, config.shortcuts)
      from_shortcut
    else
      list = [config.base, first_arg]
      list += ["src", "", "rails-root"] if config.initial_auto_expand
      reduce_expand(list)
    end

    if result && ARGV.length > 0
      list = [result] + ARGV
      result = reduce_expand(list)
    end

    puts result || "."
  end
end
