class Admin::BannersController < ApplicationController
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