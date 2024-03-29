json.array!(@scorecards) do |scorecard|
  json.extract! scorecard, :id, :checkin_count, :perfect_checkin_count, :last_checkin_date, :streak_count, :streak_record, :moods_score, :sleeps_score, :self_cares_score, :journals_score
  json.url scorecard_url(scorecard, format: :json)
end
