class Subscription < ActiveRecord::Base
  attr_accessible :period_id, :query, :query_attributes

  belongs_to :user
  belongs_to :query
  belongs_to :period

  accepts_nested_attributes_for :query

  scope :by_period, lambda { |name| joins(:period).where('periods.name' => name) }

  after_save :register

  def notify
    SubscriptionMailer.results(self).deliver if results.any?
  end

  def register
    query.model.constantize.subscribe(query.id, query.value)
  end

  def results
    return @results if @results

    @results = query.model.constantize.search(query.value).records.find_all { |e, _| period.include? e.created_at }
  end

  protected

  def query_attributes=(attributes)
    if attributes[:id]
      self.query = ::Query.find(attributes[:id])
    else
      self.query = ::Query.create(attributes)
    end
  end
end
