class FileUploadService

  def initialize(data, mindmap_id)
    @data = data
    @mindmap = Mindmap.find_by_id(mindmap_id)
  end

  def perform
    if @mindmap.mm_type == 'fileshare'
      file_name = SecureRandom.uuid + File.extname(@data['name'])
      Node.create(
        title: file_name,
        mindmap_id: @mindmap.id,
        description: @data['name']
      )

      file = @data['file']
      File.open(Rails.root.join('public', 'uploads', file_name), 'wb') do |f|
        f.write(file)
      end
      @mindmap.update(description: file_name)
      @data['file_name'] = file_name

    end
  end

end
