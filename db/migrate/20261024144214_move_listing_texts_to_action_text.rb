# The listing description and house rules become Action Text rich text. Their plain-text content is
# copied into action_text_rich_texts (as HTML paragraphs) and the old text columns are removed, so
# `has_rich_text :description` does not clash with a column of the same name.
class MoveListingTextsToActionText < ActiveRecord::Migration[8.1]
  RICH_TEXT_FIELDS = %w[description house_rules].freeze

  def up
    RICH_TEXT_FIELDS.each do |field|
      execute <<~SQL
        INSERT INTO action_text_rich_texts (name, body, record_type, record_id, created_at, updated_at)
        SELECT '#{field}', #{paragraphs_sql(field)}, 'Listing', id, created_at, updated_at
        FROM listings
        WHERE #{field} IS NOT NULL AND btrim(#{field}) <> ''
      SQL

      remove_column :listings, field
    end
  end

  def down
    RICH_TEXT_FIELDS.each do |field|
      add_column :listings, field, :text

      execute <<~SQL
        UPDATE listings
        SET #{field} = regexp_replace(rich.body, '<[^>]*>', '', 'g')
        FROM action_text_rich_texts rich
        WHERE rich.record_type = 'Listing' AND rich.record_id = listings.id AND rich.name = '#{field}'
      SQL
    end

    execute "DELETE FROM action_text_rich_texts WHERE record_type = 'Listing' AND name IN ('description', 'house_rules')"
  end

  private

  # HTML-escapes the text and turns each line into a <p>, the same way simple_format showed it.
  def paragraphs_sql(field)
    escaped = "replace(replace(replace(#{field}, '&', '&amp;'), '<', '&lt;'), '>', '&gt;')"

    "'<p>' || regexp_replace(#{escaped}, E'\\\\r?\\\\n+', '</p><p>', 'g') || '</p>'"
  end
end
