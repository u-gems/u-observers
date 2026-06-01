require 'simplecov'

SimpleCov.start do
  add_filter '/test/'

  enable_coverage :branch
end

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

# ActiveRecord is provided only by the Rails appraisals (see Appraisals).
# The baseline `rake test` run has no activerecord, so the integration tests
# are skipped automatically.
ACTIVERECORD_AVAILABLE =
  begin
    # ActiveSupport <= 6.1 references ::Logger at load time but relies on
    # another gem having required it first. Newer concurrent-ruby no longer
    # does, so require it explicitly before loading ActiveRecord.
    require 'logger'
    require 'active_record'
    require 'sqlite3'
    true
  rescue LoadError
    false
  end

if ACTIVERECORD_AVAILABLE
  require 'u-observers/for/active_record'
else
  require 'u-observers'
end

require_relative 'support'

require 'minitest/pride'
require 'minitest/autorun'
