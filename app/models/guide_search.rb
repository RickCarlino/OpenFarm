class GuideSearch
  ALL = "*"

  attr_reader :filter, :order, :query

  def initialize
    @filter = {}
    @order = { _score: :desc }
    @query = ALL
  end

  def search(query = ALL)
    query = query
    self
  end

  def self.search(query = ALL)
    new.search(query)
  end

  def ignore_drafts()
    filter[:draft] = false

    self
  end

  def for_crops(crops)
    filter[:crop_id] = []
    # filter[:crop_id] = Array(crops).map do |crop|
    #   crop.respond_to?(:id) ? crop.id : crop
    # end

    self
  end

  def with_user(user)
    return self unless user

    @order = {
      'compatibilities.score' => {
        order: 'desc',
        nested_filter: {
          term: { 'compatibilities.user_id' => user.id }
        }
      }
    }

    self
  end

  # Methods for Enumeration.
  def results
    Guide
      .order(order)
      .where(filter)
      .full_text_search(query)
  end

  def method_missing(meth, *args, &block)
    if results.respond_to?(meth)
      results.send(meth, *args, &block)
    else
      super
    end
  end

  def respond_to?(meth)
    results.respond_to?(meth)
  end

  private

  def query=(q)
    @query = (q || ALL).downcase
  end

  def empty_search?
    query == ALL
  end
end
