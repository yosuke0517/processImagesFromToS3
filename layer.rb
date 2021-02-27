require "mini_magick"
require "aws-sdk"
require 'dotenv'
Dotenv.load

def proccessImages(event:, context:)
  s3resoruce = Aws::S3::Resource.new(
    access_key_id: ENV['ACCESS_KEY'],
    secret_access_key: ENV['SECRET_ACCESS_KEY'],
    region: ENV['REGION'],
    )

  image_tmp = nil
  output_tmp_file = ""
  s3_key = ""
  start_time = Time.now

  # 指定の画像を重ねて（レイヤー）合成しoutputへアップロードする（回数増やすとなるとlambdaではなく普通にサーバーに乗せた方がコスパ良し）
  1.times do | timesCount |
    s3resoruce.client.list_objects_v2(bucket: ENV['BUCKET_NAME'], prefix: "dummyInput/").contents.each_with_index do |object, i|
      # なぜか/testのオブジェクトがindexの0に入ってくるので i >= 1でスキップ
      if i >= 1 then
        image_file = s3resoruce.client.get_object(:bucket => ENV['BUCKET_NAME'], :key => object.key).body.read
        image = MiniMagick::Image.read(image_file)

        output_tmp_file = "#{format('%012d', timesCount + 1)}.png"
        s3_key = "dummyOutput100/#{output_tmp_file}"
        # 1番最初は自分自身を重ねる
        if i == 1 then
          image_tmp = image.composite(image) do |c|
            c.compose "Over"
            c.geometry "+0+0"
          end
        end
        if i > 1 then
          image_tmp = image_tmp.composite(image) do |c|
            c.compose "Over"
            c.geometry "+0+0"
          end
        end
      end
    end

    puts "合成した画像をローカルへ配置します"
    image_tmp.write "#{output_tmp_file}"
    puts "#{output_tmp_file} をS3の #{s3_key}へアップロードします"
    s3resoruce.bucket(ENV['BUCKET_NAME']).object(s3_key).upload_file(output_tmp_file)
  end

  puts "処理時間 #{Time.now - start_time}s"
end
