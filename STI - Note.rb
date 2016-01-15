# http://stackoverflow.com/questions/5246767/sti-one-controller
# config/routes.rb
namespace :admin do
  scope :banners, :as => :banner do
    resources :homepages, :controller => :banners, :type => "Banner::Homepage" do
    end

    resources :pages, :controller => :banners, :type => "Banner::Page" do
    end
  end
end

# app/models/banner.rb 
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

# app/models/banner/homepage.rb
class Banner::Homepage < Banner
end

# app/models/banner/page.rb
class Banner::Homepage < Banner
end

# app/controllers/admin/banners_controller.rb
class Admin::BannersController < AdminController
  before_filter :load_banner
  helper_method :page_title

  def create
    if @banner.update_attributes(banner_params)
      flash[:notice] = "#{@banner.class_name_display} '#{@banner.name}' was successfully created."
      redirect_to [:admin, @banner.class]
    else
      flash[:alert] = "#{@banner.class_name_display} cannot create: #{@banner.errors.full_messages.join('. ')}" 
      render :edit
    end
  end

  def update
    if @banner.update_attributes(banner_params)
      flash[:notice] = "#{@banner.class_name_display} '#{@banner.name}' was successfully updated."
      redirect_to [:admin, @banner.class]
    else
      flash[:alert] = "#{@banner.class_name_display} '#{@banner.name}' cannot update: #{@banner.errors.full_messages.join('. ')}" 
      render :edit
    end
  end

  def destroy
    if @banner && @banner.destroy
      flash[:notice] = "#{@banner.class_name_display} '#{@banner.name}' was successfully destroyed."
    else
      flash[:alert] = "#{@banner.class_name_display} '#{@banner.name}' cannot destroy: #{@banner.errors.full_messages.join('. ')}" 
    end
    
    redirect_to :back
  end

  private
  def banner_params
    params_key = params.has_key?(:banner_homepage) ? :banner_homepage : :banner_page
    params.require(params_key).permit(:name, :type, :attachment, :active, :position, :data)
  end

  def load_banner
    if %w(index).include? action_name
      @banners = resource.order(:position)
    else
      @banner = params[:id].present? ? resource.find(params[:id]) : resource.new
    end
  end

  def resource
    @resource ||= params[:type].singularize.titleize.camelize.constantize
  end

  def page_title 
    params[:type].to_s.split('::').join(' ') rescue ''
  end
end

# app/views/admin/banners/index.html.haml
= content_for :sidebar_title do
  .row
    .col-sm-6
      .title-1
        = page_title.pluralize
    .col-sm-6
      = link_to [:new, :admin, @resource.model_name.param_key], :class => "button-default h35 hit-top pull-right fa fa-plus" do
        %span.text= "New #{page_title}"

%table.table.table-style-1
  %thead
    %tr
      %th Name
      %th File Name
      %th Thumbs
      %th{:style => 'width: 75px;'} Status
      %th Actions
  %tbody
    - @banners.each do |banner|
      %tr
        %td= banner.name
        %td= banner.attachment_file_name
        %td= image_tag banner.attachment.url, :width => '70px'
        %td.text-center.margin-0.padding-0
          = content_tag :div, '', :class => "state #{banner.active ? 'active' : 'inactive'}"
        %td.actions.actions-2
          = link_to '', [:edit, :admin, banner], :class => 'edit-button'
          = link_to '', [:admin, banner], :class => 'delete-button', method: :delete, :data => { :confirm => "Are you sure?"}

# app/views/admin/banners/new.html.haml
= link_to "Back to #{@banner.class_name_display} List", [:admin, @banner.class]
= form_for [:admin, @banner] do |f|
  .title-3= "New #{@banner.class_name_display}"
  %hr.less-margin/
  = render :partial => 'form', :locals => { :f => f }
  .form-buttons.filter-actions.actions{"data-hook" => "buttons"}
    = link_to 'cancel', [:admin, @banner.class]
    = f.submit :create

# app/views/admin/banners/edit.html.haml
= link_to "Back to #{@banner.class_name_display} List", [:admin, @banner.class]
= form_for [:admin, @banner] do |f|
  .title-3= "New #{@banner.class_name_display}"
  %hr.less-margin/
  = render :partial => 'form', :locals => { :f => f }
  .form-buttons.filter-actions.actions{"data-hook" => "buttons"}
    = link_to 'cancel', [:admin, @banner.class]
    = f.submit :update

# app/views/admin/banners/_form.html.haml
.row
  .col-sm-6
    = f.label :name, 'Name*'
    = f.text_field :name, :required => true
  .col-sm-6
    - size = params[:type] == 'Banner::Homepage' ? '960x330' : '960x95'
    = f.label :attachment, "Attachment* (#{size})"
    = f.file_field :attachment, onchange: 'Attachment.UpdatePreview(this)', required: f.object.new_record?
%br/
.row
  .col-sm-6
    %label{:for => ""} Preview
    - image_url = f.object.attachment.url rescue image_path("noimage/large.png")
    = image_tag image_url, :class => 'img-responsive', id:"image-preview"
  .col-sm-6
    %label.no-padding
      = f.check_box :active
      %span.title-5.margin-left-5 Active

:javascript
  $(function(){
    Attachment = {
      UpdatePreview: function(obj){
        if(!window.FileReader){
        } else {
          var reader = new FileReader();
          var target = null;
          reader.onload = function(e) {
            target =  e.target || e.srcElement;
            $("#image-preview").prop("src", target.result);
          };
          reader.readAsDataURL(obj.files[0]);
        }
      }
    };
  });