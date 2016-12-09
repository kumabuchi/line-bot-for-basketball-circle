class QrCode
  def create(text)
    qr = RQRCode::QRCode.new(text, size: 10, level: :m )
    png = qr.to_img
    rnd = User.generate_random(50)
    png.resize(200, 200).save("static/qr/#{rnd}.png")
    "#{BASE_URL}static/qr/#{rnd}.png"
  end
end
