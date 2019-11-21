# frozen_string_literal: true

require "cases/helper"
require "models/book"

class Mysql2UseIndexTest < ActiveRecord::Mysql2TestCase
  fixtures :books

  def test_use_index_when_given_column_names
    assert_equal(
      "SELECT `books`.* FROM `books` USE INDEX (index_books_on_author_id_and_name)",
      Book.use_index([:author_id, :name]).to_sql
    )
  end

  def test_use_index_when_given_index_name
    assert_equal(
      "SELECT `books`.* FROM `books` USE INDEX (index_books_on_author_id_and_name)",
      Book.use_index(:index_books_on_author_id_and_name).to_sql
    )
  end

  def test_use_index_when_index_is_not_found
    assert_equal(
      "SELECT `books`.* FROM `books`",
      Book.use_index(:non_existent_index).to_sql
    )
  end

  def test_use_index_with_multiple_index_names
    assert_equal(
      "SELECT `books`.* FROM `books` USE INDEX (index_books_on_author_id_and_name,index_books_on_isbn)",
      Book.use_index(:index_books_on_author_id_and_name, :index_books_on_isbn).to_sql
    )
  end

  def test_use_index_with_index_name_and_columns
    assert_equal(
      "SELECT `books`.* FROM `books` USE INDEX (index_books_on_author_id_and_name,index_books_on_isbn)",
      Book.use_index(:index_books_on_author_id_and_name, :isbn).to_sql
    )
  end

  def test_use_index_with_multiple_sets_of_columns
    assert_equal(
      "SELECT `books`.* FROM `books` USE INDEX (index_books_on_author_id_and_name,index_books_on_isbn)",
      Book.use_index([:author_id, :name], :isbn).to_sql
    )
  end
end
