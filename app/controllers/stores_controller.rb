class StoresController < ApplicationController
  def index
    if request.xhr?
      if params['required'] == 'all'
        @filtered_results = Product.all
      else
        @filtered_results = Product.filter_by_body_shape(current_user)
      end
      respond_to do |format|
        format.html
        format.json { render json: @filtered_results }
      end
    end
  end
end
