class PropertiesController < ApplicationController
  before_action :set_property, only: :show

  def index
    @properties = Property.includes(:neighborhood, :host, :listings).order(:title)
  end

  def show
  end

  private

  def set_property
    @property = Property.includes(:neighborhood, :host, :amenities, :listings).find(params[:id])
  end
end
