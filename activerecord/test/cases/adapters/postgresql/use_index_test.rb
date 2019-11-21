# frozen_string_literal: true

require "cases/helper"
require "models/book"

class PostgreSQLUseIndexTest < ActiveRecord::PostgreSQLTestCase
  fixtures :books

  def test_use_index_is_a_noop_on_postgres
    assert_equal(
      "SELECT `books`.* FROM `books`",
      Book.use_index(:author_id, :name).to_sql
    )
  end
end
