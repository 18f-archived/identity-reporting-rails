FactoryBot.define do
  factory :stl_unload_log do
    start_time { Time.zone.now }
    end_time { Time.zone.now }
    userid { 1 }
    path { 's3://bucket/folder/file.csv' }
  end
end
