# frozen_string_literal: true

require 'volterra/collections'

module VolterraInspec
  # Represents the metadata property that is common to all Volterra resources.
  class Metadata
    attr_reader :annotatons, :description, :disable, :labels, :name, :namespace

    def initialize(data)
      @annotations = VolterraInspec::LookupHash.create(data.fetch(:annotations, {})).freeze
      @description = data.fetch(:description, nil).freeze
      @disable = data.fetch(:disable, false).freeze
      @labels = VolterraInspec::LookupHash.create(data.fetch(:labels, {})).freeze
      @name = data.fetch(:name).freeze
      @namespace = data.fetch(:namespace).freeze
    end

    def to_s
      "Metadata #{@namespace}/#{@name}"
    end
  end
end
