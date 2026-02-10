json.extract! attendance_record, :id, :member_id, :date, :is_present, :created_at, :updated_at
json.url attendance_record_url(attendance_record, format: :json)
