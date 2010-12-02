class Admin::SearchesController < ApplicationController
  around_filter :ensure_user_can_administer
  layout 'page'

  def index
    @searches = StagedSearch.find(:all, :order => "query asc")
  end

  def real
    @searches = Search.find(:all, :limit => 100, :order => "created_at desc")
  end


  def edit
    @search = StagedSearch.find(params[:id])
  end

  def new
    @search = StagedSearch.new
  end

  def create
    @search = StagedSearch.new(params[:staged_search])
    @search.save
    redirect_to :action => "index"
  end

  def update
    @search = StagedSearch.find(params[:id])
    @search.update_attributes(params[:staged_search])
    @search.save
    redirect_to :action => "index"
  end

  def destroy
    StagedSearch.destroy params[:id]
    redirect_to :action => "index"
  end

  private
  def ensure_user_can_administer
    if user_can_administer?
      yield
    else
      redirect_to '/'
    end
  end

end
