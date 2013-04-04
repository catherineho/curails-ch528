class AvatarUploader < CarrierWave::Uploader::Base
    include Cloudinary::CarrierWave
    process :convert => 'png'
    
    version :standard do
    cloudinary_transformation :radius => 20,
    :width => 200,
    :height => 300,
    :crop => :thumb
end

version :thumbnail do
    cloudinary_transformation :effect => "sepia",
    :width => 50,
    :height => 50,
    :crop => :thumb,
    :gravity => :face
end
end