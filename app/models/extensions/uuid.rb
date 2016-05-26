module Extensions
  module UUID
    extend ActiveSupport::Concern

    included do
      #set_primary_key 'uuid'
      before_create :generate_uuid

      def generate_uuid
        self.uuid = SecureRandom.uuid
      end
    end
  end
end
