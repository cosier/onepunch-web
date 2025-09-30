# Summarize module for text summarization
# This module will be upgraded to use LLM in the future
# For now, it uses simple heuristics for text summarization
module Summarize
  class << self
    def generate(text)
      return "" if text.blank?

      # Split text into individual entries
      entries = text.split("\n---\n").map(&:strip).reject(&:blank?)

      return "" if entries.empty?

      if entries.size == 1
        # Single entry - just clean and truncate it
        summarize_single_entry(entries.first)
      else
        # Multiple entries - combine intelligently
        summarize_multiple_entries(entries)
      end
    end

    private

    def summarize_single_entry(text)
      # Remove extra whitespace and truncate
      cleaned = text.gsub(/\s+/, ' ').strip

      if cleaned.length <= 150
        cleaned
      else
        # Smart truncate at word boundary
        truncated = cleaned[0..147]
        last_space = truncated.rindex(' ')
        truncated = truncated[0..last_space-1] if last_space
        "#{truncated}..."
      end
    end

    def summarize_multiple_entries(entries)
      # Group similar entries
      grouped = group_similar_entries(entries)

      if grouped.size == 1
        # All entries are similar
        key, items = grouped.first
        "#{items.size} entries: #{summarize_single_entry(key)}"
      elsif grouped.size <= 3
        # A few different activities
        summaries = grouped.map do |key, items|
          if items.size == 1
            summarize_single_entry(key)
          else
            "#{summarize_single_entry(key)} (#{items.size}x)"
          end
        end
        summaries.join("; ")
      else
        # Many different activities
        total = entries.size
        main_activities = grouped.sort_by { |_, items| -items.size }.first(2)
        main_summaries = main_activities.map do |key, items|
          "#{summarize_single_entry(key)} (#{items.size}x)"
        end

        if main_summaries.size == 2
          "#{total} activities including: #{main_summaries.join(' and ')}"
        else
          "#{total} activities including: #{main_summaries.first}"
        end
      end
    end

    def group_similar_entries(entries)
      grouped = {}

      entries.each do |entry|
        # Normalize entry for grouping
        normalized = normalize_entry(entry)

        # Find or create group
        key = grouped.keys.find { |k| similar?(k, normalized) } || normalized
        grouped[key] ||= []
        grouped[key] << entry
      end

      grouped
    end

    def normalize_entry(text)
      # Remove timestamps, numbers, and common words to find similarity
      text.downcase
          .gsub(/\b\d+:\d+\b/, '')  # Remove times
          .gsub(/\b\d+\b/, '')       # Remove numbers
          .gsub(/\b(the|a|an|and|or|but|in|on|at|to|for)\b/, '') # Remove common words
          .gsub(/[^\w\s]/, '')       # Remove punctuation
          .gsub(/\s+/, ' ')          # Normalize whitespace
          .strip
    end

    def similar?(text1, text2)
      # Simple similarity check - could be enhanced with better algorithms
      return true if text1 == text2

      # Check if one contains significant part of the other
      words1 = text1.split(' ')
      words2 = text2.split(' ')

      # If texts are very short, require exact match
      return false if words1.size < 3 || words2.size < 3

      # Find common words
      common = words1 & words2
      similarity_ratio = common.size.to_f / [words1.size, words2.size].min

      # Consider similar if 60% of words match
      similarity_ratio >= 0.6
    end
  end
end