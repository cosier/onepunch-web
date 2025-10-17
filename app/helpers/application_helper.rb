module ApplicationHelper
  def format_duration(seconds)
    return "0:00:00" if seconds.nil? || seconds.zero?

    hours = seconds / 3600
    minutes = (seconds % 3600) / 60
    seconds = seconds % 60

    format("%d:%02d:%02d", hours, minutes, seconds)
  end
end
