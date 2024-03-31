# frozen_string_literal: true

require 'volterra/collections'

module VolterraInspec
  # Represents the system generated metadata that is associated with Volterra resources.
  class SystemMetadata
    attr_reader :creation_timestamp, :creator_class, :creator_id, :deletion_timestamp, :finalizers, :initializers,
                :labels, :modification_timestamp, :object_index, :owner_view, :tenant, :uid

    # rubocop:disable Metrics/MethodLength
    def initialize(data)
      @creation_timestamp = VolterraInspec.parse_timestamp(data.fetch(:creation_timestamp, nil)).freeze
      @creator_class = data.fetch(:creator_class, nil).freeze
      @creator_id = data.fetch(:creator_id, nil).freeze
      @deletion_timestamp = VolterraInspec.parse_timestamp(data.fetch(:deletion_timestamp, nil)).freeze
      @finalizers = VolterraInspec.parse_array(data.fetch(:finalizers, [])).freeze
      @initializers = VolterraInspec.parse_array(data.fetch(:initializers, [])).freeze
      @labels = VolterraInspec::LookupHash.create(data.fetch(:labels, {})).freeze
      @modification_timestamp = VolterraInspec.parse_timestamp(data.fetch(:modification_timestamp, nil)).freeze
      @object_index = data.fetch(:object_index, nil).freeze
      @owner_view = data.fetch(:owner_view, nil).freeze
      @tenant = data.fetch(:tenant, nil).freeze
      @uid = data.fetch(:uid, nil).freeze
    end
    # rubocop:enable Metrics/MethodLength

    def to_s
      "SystemMetadata #{@uid}"
    end
  end
end
