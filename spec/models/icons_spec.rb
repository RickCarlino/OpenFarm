# frozen_string_literal: true
require 'spec_helper'

svg = File.read('./spec/fixtures/cantaloupe.svg')

describe Icon do
  it 'has an svg' do
    Icon.reindex
    user = FactoryGirl.create(:user)
    i    = Icon.create!(svg: svg,
                        description: 'Lorem ipsum',
                        name: 'cantaloupe',
                        user: user)
    i.reload
    expect(i.name).to eq('cantaloupe')
    expect(i.svg).to eq(svg)
    expect(i.user).to eq(user)
  end

  it 'has and belongs to `Crop`s' do
    Icon.reindex
    user  = FactoryGirl.create(:user)
    crops = FactoryGirl.create_list(:crop, 3)
    i     = Icon.create!(svg: svg,
                         description: 'Lorem ipsum',
                         name: 'cantaloupe',
                         user: user,
                         crops: crops)
    i.reload
    expect(i.crops.length).to eq(3)
  end
end
