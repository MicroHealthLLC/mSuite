class FilesController < ApplicationController
  def index
    @files = Dir.glob(Rails.root.join('public', 'uploads', '*'))
  end

  def download
    send_file Rails.root.join('public', 'uploads', params[:filename]), type: 'application/octet-stream', x_sendfile: true
  end

  # def file_downloaded
  #   filename = params[:filename]
  #   if FileManagementService.new(filename, 'download').delete_file
  #     render json: { message: "File downloaded successfully" }
  #   else
  #     render json: { error: "Could not download file" }, status: :unprocessable_entity
  #   end
  # end

  def file_canceled
    filename = params[:filename]
    if FileManagementService.new(filename, 'cancel').delete_file
      render json: { message: "File deleted successfully" }
    else
      render json: { error: "Could not delete file" }, status: :unprocessable_entity
    end
  end
end
