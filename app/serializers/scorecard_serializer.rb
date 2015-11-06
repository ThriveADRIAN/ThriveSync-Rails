class ScorecardSerializer < ActiveModel::Serializer
  attributes :id, :checkin_count, :perfect_checkin_count, :last_checkin_date, :last_perfect_checkin_date, :streak_count, :streak_record, :moods_score, :sleeps_score, :self_cares_score, :journals_score, :level_multiplier, :days_since_signup, :user_id, :mood_checkin_count, :mood_last_checkin_date, :mood_streak_count, :mood_streak_record, :mood_level_multiplier, :sleep_checkin_count, :sleep_last_checkin_date, :sleep_streak_count, :sleep_streak_record, :sleep_level_multiplier, :self_care_checkin_count, :self_care_last_checkin_date, :self_care_streak_count, :self_care_streak_record, :self_care_level_multiplier, :journal_checkin_count, :journal_last_checkin_date, :journal_streak_count, :journal_streak_record, :journal_level_multiplier, :total_score, :checkin_goal, :checkin_sunday, :checkin_monday, :checkin_tuesday, :checkin_wednesday, :checkin_thursday, :checkin_friday, :checkin_saturday, :checkins_to_reach_goal
end
