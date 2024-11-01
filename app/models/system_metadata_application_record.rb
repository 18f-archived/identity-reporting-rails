# rubocop:disable Rails/ApplicationRecord
class SystemMetadataApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  connects_to database: { writing: :system_metadata, reading: :system_metadata }
end
# rubocop:enable Rails/ApplicationRecord
