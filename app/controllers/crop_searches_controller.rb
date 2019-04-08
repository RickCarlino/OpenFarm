class CropSearchesController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :search

  def search
    query = params[:q].to_s.encode("utf-8", "iso-8859-1")

    @crops = Crop
      .full_text_search(query)
      .limit(25)
    if query.blank?
      @crops = Crop.search("*", limit: 25, boost_by: [:guides_count])
    end

    search = GuideSearch.search("*").ignore_drafts.for_crops(@crops).with_user(current_user)

    @guides = Guide.sorted_for_user(search, current_user)

    render :show
  end

  private

  def sort_guides(current_user)
  end
end
