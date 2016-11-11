class GeocodeWorker
  include Sidekiq::Worker
  sidekiq_options :queue => :geocode

  def perform(import_id, ids = nil)


  end
end
