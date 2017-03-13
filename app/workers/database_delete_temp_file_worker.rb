class DatabaseDeleteTempFileWorker
  include Sidekiq::Worker
  require "google_drive"
  sidekiq_options queue: "high"

  def perform(id)
    session = GoogleDrive::Session.from_config("#{Rails.root}/config/google-sheets.json")
    g_files = session.files(q: ["name = ?", "#{id}_temp"])
    g_files.each do |file|
      session.drive.delete_file(file.id)
    end
  end
end