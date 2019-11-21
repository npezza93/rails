# frozen_string_literal: true

require "cases/helper"
require "models/book"

class SQLite3UseIndexTest < ActiveRecord::SQLite3TestCase
  fixtures :books

  def test_use_index_is_a_noop_on_sqlite
    assert_equal(
      "SELECT `books`.* FROM `books`",
      Book.use_index(:author_id, :name).to_sql
    )
  end
end
