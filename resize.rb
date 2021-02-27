require "mini_magick"
require "aws-sdk"
require 'dotenv'
Dotenv.load
s3resoruce = Aws::S3::Resource.new(
  access_key_id: ENV['ACCESS_KEY'],
  secret_access_key: ENV['SECRET_ACCESS_KEY'],
  region: ENV['REGION'],
  )

#inputに入っている画像を取り出してリサイズ（300x300）してoutputへアップロードする
s3resoruce.client.list_objects_v2(bucket: ENV['BUCKET_NAME'], prefix: "dummyInput/").contents.each_with_index do |object, i|
  if i >= 1 then
    puts "NAME: #{object.key}"
    image_file = s3resoruce.client.get_object(:bucket => ENV['BUCKET_NAME'], :key => object.key).body.read
    image = MiniMagick::Image.read(image_file)

    resized_tmp_file = "out_#{object.key.delete("dummyInput/")}"
    s3_key = "dummyOutput/#{resized_tmp_file}"
    image.resize("300x300").write(resized_tmp_file)
    puts "#{resized_tmp_file} をS3の #{s3_key}へアップロードします"
    # image.write file_name
    s3resoruce.bucket(ENV['BUCKET_NAME']).object(s3_key).upload_file(resized_tmp_file)
  end
end