class Message
  def self.create_text_obj(text)
    {
      type: 'text',
      text: text
    }
  end

  def self.create_image_obj(image_url)
    {
      type: 'image',
      originalContentUrl: image_url,
      previewImageUrl: image_url
    }
  end

  def self.create_sticker_obj(sticker_id, package_id)
    {
      type: 'sticker',
      packageId: package_id,
      stickerId: sticker_id
    }
  end
end
