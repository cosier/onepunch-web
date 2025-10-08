# Configure Solid Queue to use the queue database
Rails.application.config.to_prepare do
  SolidQueue::Record.connects_to database: { writing: :queue, reading: :queue }
end