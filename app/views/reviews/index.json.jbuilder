json.array!(@reviews) do |review|
  json.extract! review, :id, :last_login_date, :review_counter, :review_last_date, :review_trigger_date
  json.url review_url(review, format: :json)
end
