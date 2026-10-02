# Rewrites the enum check constraints as `column::text IN (...)`.
#
# PostgreSQL stores a plain `column IN (...)` on a varchar column in a form that changes once
# it is loaded back from db/schema.rb, so schema.rb kept showing spurious diffs depending on
# whether a database was built from migrations or from the schema. The `::text` form is stored
# identically either way. The rule each constraint enforces does not change.
class NormalizeEnumCheckConstraints < ActiveRecord::Migration[8.1]
  CONSTRAINTS = {
    users: {
      "users_role_valid" => %w[role member moderator],
      "users_status_valid" => %w[status active suspended]
    },
    properties: {
      "properties_type_valid" => %w[property_type apartment house studio]
    },
    listings: {
      "listings_status_valid" => %w[status draft published reserved rented withdrawn]
    }
  }.freeze

  def up
    each_constraint do |table, name, column, values|
      remove_check_constraint table, name: name
      add_check_constraint table, "#{column}::text IN (#{quoted(values)})", name: name
    end
  end

  def down
    each_constraint do |table, name, column, values|
      remove_check_constraint table, name: name
      add_check_constraint table, "#{column} IN (#{quoted(values)})", name: name
    end
  end

  private

  def each_constraint
    CONSTRAINTS.each do |table, constraints|
      constraints.each do |name, (column, *values)|
        yield table, name, column, values
      end
    end
  end

  def quoted(values)
    values.map { |value| connection.quote(value) }.join(", ")
  end
end
