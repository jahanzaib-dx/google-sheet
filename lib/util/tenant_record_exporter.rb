module TenantRecordExporter
  @@root = Rails.root.join('public','export')

  def self.export_file(criteria, user_id, type = :pdf, req = nil, is_cushman_user, template_id)
    #create file
    uuid = UUIDTools::UUID.random_create.to_s
    path = self.path("#{uuid}.#{type}")

    begin
      fd = File.new path, 'wb' # touch file
      fd.close

      case type
      when :pdf
        # begin file export
        req_env = {
          "SERVER_PROTOCOL" => req.env["SERVER_PROTOCOL"],
          "REQUEST_URI" => req.env["REQUEST_URI"],
          "SERVER_NAME" => req.env["SERVER_NAME"],
          "SERVER_PORT" => req.env["SERVER_PORT"],
          "rack.input" => req.env["rack.input"]
        }

        GeneratePdfReportWorker.perform_async(path, criteria, user_id, req_env, is_cushman_user, template_id)
      when :xls
        GenerateExcelReportWorker.perform_async path, criteria, user_id
      else
        raise 
      end
    rescue => error
      raise error
      File.unlink path
    end

    File.basename path
  end

  def self.exists?(filename)
    File.exists? self.path(filename)
  end

  def self.path(filename)
    (@@root + filename).to_s
  end

  def self.done?(filename)
    File.size(self.path filename) > 0
  end

  def self.mime_type(filename)
    Mime::Type.lookup_by_extension File.extname(filename)[1..-1]
  end
end
