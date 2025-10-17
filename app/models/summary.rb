class Summary < ApplicationRecord
  # Status values
  STATUSES = %w[pending processing completed failed].freeze

  # Validations
  validates :unique_slug, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }

  # Scopes
  scope :pending, -> { where(status: 'pending') }
  scope :processing, -> { where(status: 'processing') }
  scope :completed, -> { where(status: 'completed') }
  scope :failed, -> { where(status: 'failed') }
  scope :recent, -> { order(created_at: :desc) }

  # Class methods
  def self.find_or_create_for(slug, text_array = [])
    summary = find_or_initialize_by(unique_slug: slug)

    if summary.new_record?
      summary.text_to_summarize = text_array.join("\n---\n")
      summary.status = 'pending'
      summary.save!
      summary.process!
    elsif summary.stale?
      summary.update!(
        text_to_summarize: text_array.join("\n---\n"),
        status: 'pending'
      )
      summary.process!
    end

    summary
  end

  def self.generate_slug(date, project_id, entry_count)
    "#{date.strftime('%Y%m%d')}_project_#{project_id}_entries_#{entry_count}"
  end

  # Instance methods
  def process!
    return if processing? || completed?

    update!(status: 'processing')

    begin
      # Placeholder for future LLM integration
      # For now, use simple truncation heuristics
      result = Summarize.generate(text_to_summarize)

      update!(
        summarized_text: result,
        status: 'completed'
      )
    rescue => e
      update!(
        status: 'failed',
        metadata: metadata.merge('error' => e.message)
      )
      raise e
    end
  end

  def stale?
    # Consider summary stale if older than 24 hours
    # Or if it failed
    failed? || created_at < 24.hours.ago
  end

  def pending?
    status == 'pending'
  end

  def processing?
    status == 'processing'
  end

  def completed?
    status == 'completed'
  end

  def failed?
    status == 'failed'
  end

  def ready?
    completed? && summarized_text.present?
  end
end