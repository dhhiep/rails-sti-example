class Banner < ActiveRecord::Base
  has_attached_file :attachment,
  :s3_credentials => 
    {
      :access_key_id      => ENV['AWS_ACCESS_KEY_ID'],
      :secret_access_key  => ENV['AWS_SECRET_ACCESS_KEY'],
      :bucket             => ENV['S3_BUCKET_NAME']
    },
  :storage      => :s3,
  :s3_headers   => { "Cache-Control" => "max-age=31557600" },
  :s3_protocol  => "https",
  :bucket       => ENV['S3_BUCKET_NAME'],
  :url          => ":s3_domain_url",
  :styles => {},
  :default_style    => "product",
  :path             => "/banner/:id/:basename.:extension",
  :default_url      => "/banner/:id/:basename.:extension",
  :convert_options  => { all: '-strip -auto-orient -colorspace sRGB' }

  validates_attachment :attachment,
    :presence => true,
    :content_type => { :content_type => %w(image/jpeg image/jpg image/png image/gif) }

  def class_name_display
    self.class.to_s.split('::').join(' ')
  end
end