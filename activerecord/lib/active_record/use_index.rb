# frozen_string_literal: true

module ActiveRecord
  # Allow passing index hints to MySQL in case the query planner gets confused.
  #
  # MySQL documentation:
  #    https://dev.mysql.com/doc/refman/8.0/en/index-hints.html
  #
  # Example:
  #   Book.use_index(:index_books_on_author_id_and_name)
  #
  #   => Book Load (0.5ms)  SELECT `books`.* FROM `books` USE INDEX (index_books_on_author_id_and_name)
  #
  #   Book.use_index([:author_id, :name])
  #
  #   => Book Load (0.5ms)  SELECT `books`.* FROM `books` USE INDEX (index_books_on_author_id_and_name)
  #
  #   Book.use_index(:index_books_on_author_id_and_name, :index_books_on_isbn)
  #
  #   => Book Load (0.5ms)  SELECT `books`.* FROM `books` USE INDEX (index_books_on_author_id_and_name,index_books_on_isbn)
  #
  #   Book.use_index(:index_books_on_author_id_and_name, :isbn)
  #
  #   => Book Load (0.5ms)  SELECT `books`.* FROM `books` USE INDEX (index_books_on_author_id_and_name,index_books_on_isbn)
  #
  #   Book.use_index([:author_id, :name], :index_books_on_isbn)
  #
  #   => Book Load (0.5ms)  SELECT `books`.* FROM `books` USE INDEX (index_books_on_author_id_and_name,index_books_on_isbn)
  #
  module UseIndex
    extend ActiveSupport::Concern

    class IndexFinder
      def initialize(connection, table_name, names_and_columns)
        @connection = connection
        @table_name = table_name
        @names_and_columns = names_and_columns
      end

      def index_list
        @index_list ||=
          names_and_columns.map do |name_or_columns|
            table_indexes.find do |index|
              by_name(name_or_columns, index).presence ||
                by_columns(name_or_columns, index)
            end&.name
          end.compact.join(",")
      end

      def index_list?
        index_list.present?
      end

      private

      attr_reader :connection, :table_name, :names_and_columns

      def by_name(name, index)
        name.to_s == index.name.to_s
      end

      def by_columns(columns, index)
        Array.wrap(columns).map(&:to_s).sort == index.columns.sort
      end

      def table_indexes
        @table_indexes ||= connection.schema_cache.indexes(table_name)
      end
    end

    module ClassMethods
      def use_index(*names_and_columns)
        index_finder =
          IndexFinder.new(connection, table_name, names_and_columns)

        if connection.supports_use_index? && index_finder.index_list?
          from "#{quoted_table_name} USE INDEX (#{index_finder.index_list})"
        else
          from(quoted_table_name)
        end
      end
    end
  end
end
