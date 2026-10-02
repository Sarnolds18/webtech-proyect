class NeighborhoodsController < ApplicationController
  before_action :set_neighborhood, only: :show

  def index
    @neighborhoods = Neighborhood.all
  end

  def show
  end

  private

  def set_neighborhood
    @neighborhood = Neighborhood.find(params[:id])
  end
end
