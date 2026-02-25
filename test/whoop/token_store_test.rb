require_relative "../test_helper"
require "tmpdir"

class TokenStoreTest < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
    @token_file = File.join(@tmpdir, "tokens.json")
    @store = Whoop::TokenStore.new(token_file_path: @token_file)
  end

  def teardown
    FileUtils.remove_entry(@tmpdir)
  end

  def test_update_persists_tokens
    @store.update!(access_token: "abc", refresh_token: "xyz", expires_in: 3600)

    assert_equal "abc", @store.access_token
    assert_equal "xyz", @store.refresh_token
    assert File.exist?(@token_file)
  end

  def test_expired_returns_true_when_no_expiry
    assert @store.expired?
  end

  def test_expired_returns_false_when_not_expired
    @store.update!(access_token: "a", refresh_token: "b", expires_in: 3600)
    refute @store.expired?
  end

  def test_expires_soon_with_margin
    @store.update!(access_token: "a", refresh_token: "b", expires_in: 100)
    assert @store.expires_soon?(300)
  end

  def test_seed_creates_file_only_once
    @store.seed!(access_token: "first")
    assert_equal "first", @store.access_token

    @store.seed!(access_token: "second")
    assert_equal "first", @store.access_token
  end

  def test_loads_from_existing_file
    @store.update!(access_token: "persisted", refresh_token: "ref", expires_in: 3600)

    new_store = Whoop::TokenStore.new(token_file_path: @token_file)
    assert_equal "persisted", new_store.access_token
  end
end
