require_relative 'test_helper'
require 'fileutils'
require 'camping/loader'

# This test file is mostly the same as reload_reloader.rb.
# Except this checks to see if a config.ru app is reloaded correctly.

$counter = 0

# for Reloading stuff
module TestCaseLoader

  def loader
    @loader ||= Camping::Loader.new(file)
  end

  def before_all
    super
    move_to_reloader
    loader.reload!
    assert Object.const_defined?(:Reloader), "Reloader didn't load app"
  end

  def after_all
    assert Object.const_defined?(:Reloader), "Test removed app"
    loader.remove_constants
    # breaks in CI for some reason.
    # assert !Object.const_defined?(:Reloader), "Loader didn't remove app"
    leave_reloader
    super
  end

end

class TestConfigRu < TestCase
  include TestCaseLoader

  BASE = File.expand_path('../apps/reloader', __FILE__)
  def file; BASE + '/config.ru' end

  def setup
    super
    $counter = 0
    loader.reload!
  end

  def test_counter
    assert_equal 1, $counter
  end

  def test_forced_reload
    loader.reload!
    assert_equal 2, $counter
  end

  def test_that_touch_was_touched
    FileUtils.touch(BASE + '/reloader.rb')
    assert_equal 1, $counter
  end

  def test_mtime_reload
    loader.reload
    assert_equal 1, $counter

    FileUtils.touch(BASE + '/reloader.rb')
    loader.reload
    assert_equal 2, $counter

    FileUtils.touch(BASE + '/reload_me.rb')
    loader.reload
    assert_equal 3, $counter
  end

  def test_name
    assert_equal Reloader, loader.apps[:reloader]
  end

end
