# frozen_string_literal: true

require 'ipaddr'
require 'time'
require 'volterra/collections'

# The VolterraInspec module contains reusable helpers and resource definitions for Volterra resources.
module VolterraInspec
  # Parses the supplied address string to an IPAddr or nil.
  def self.parse_ipaddress(address)
    return nil if address.nil? || address.empty?

    IPAddr.new(address).freeze
  end

  # Parses an array of values into a LookupArray of typed objects.
  def self.parse_array(data, klass = String)
    return nil if data.nil?
    raise "Unexpected data type for parse_array: #{data}" unless data.is_a?(Array)

    VolterraInspec::LookupArray.new(data.map { |value| klass.new(value).freeze }).freeze
  end

  # Helper to parse an empty object (e.g. no_dc_cluster_group, no_forward_proxy, etc.).
  def self.parse_empty_object(data)
    return nil if data.nil? || data.empty?

    data.keys.first.to_s.freeze
  end

  # Helper to parse an ISO8601 timestamp to a Time object.
  def self.parse_timestamp(data)
    return nil if data.nil? || data.empty?

    Time.parse(data).freeze
  end
end
