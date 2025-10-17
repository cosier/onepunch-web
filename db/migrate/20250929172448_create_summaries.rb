class CreateSummaries < ActiveRecord::Migration[8.1]
  def change
    create_table :summaries do |t|
      t.string :unique_slug, null: false
      t.text :text_to_summarize
      t.text :summarized_text
      t.string :status, default: 'pending'
      t.json :metadata, default: {}

      t.timestamps
    end
    add_index :summaries, :unique_slug, unique: true
    add_index :summaries, :status
    add_index :summaries, :created_at
  end
end
