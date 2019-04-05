require "spec_helper"

describe CropSearchesController, type: "controller" do
  it "should search associated guides and return published guides" do
    crop = FactoryBot.create(:crop, name: "Carrot")
    guide = FactoryBot.create(:guide, crop: crop, draft: false)
    other_guide = FactoryBot.create(:guide)

    Legacy._get self, "search", q: "carrot"

    expect(assigns[:guides].results).to include(guide)
    expect(assigns[:guides].results).to_not include(other_guide)
  end

  it "should not find draft guides" do
    crop = FactoryBot.create(:crop, name: "Carrot")
    guide = FactoryBot.create(:guide, crop: crop, draft: true)
    other_guide = FactoryBot.create(:guide)

    Legacy._get self, "search", q: "carrot"

    expect(assigns[:guides].results).to_not include(guide)
    expect(assigns[:guides].results).to_not include(other_guide)
  end

  it "should order guides by compatibility" do
    skip "fails on CI - RickCarlino"
    user = FactoryBot.create(:confirmed_user)
    garden = Garden.all.last
    garden.update_attributes(soil_type: "Loam",
                             type: "Outside",
                             average_sun: "Full Sun")
    garden.save

    crop = FactoryBot.create(:crop, name: "Carrot")

    uncompatible_guide = FactoryBot.create(:guide, crop: crop, draft: false)
    Stage.create(guide: uncompatible_guide,
                 environment: ["Potted"],
                 soil: ["Clay"],
                 light: ["Partial Sun"])

    compatible_guide = FactoryBot.create(:guide, crop: crop, draft: false)
    Stage.create(guide: compatible_guide,
                 environment: ["Outside"],
                 soil: ["Loam"],
                 light: ["Full Sun"])

    sign_in user
    Legacy._get self, "search", q: "carrot"

    expect(assigns[:guides].first).to eq(compatible_guide)
  end
end
