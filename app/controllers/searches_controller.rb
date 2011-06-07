require 'tire_pagination_hack.rb'

class SearchesController < ApplicationController
  helper_method :sort_column, :sort_direction

  # GET /searches
  # GET /searches.json
  def index
    @searches = Search.order_by([:updated_at, :desc])

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @searches }
    end
  end

  # GET /searches/1
  # GET /searches/1.json
  def show
    @search = Search.where(:slug => params[:id]).first
    @search.filters = params[:filter] ? params[:filter][0] : {}
    @es = @search.get_results params[:page], sort_column, sort_direction

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @search }
    end
  end

  # GET /searches/new
  # GET /searches/new.json
  def new
    @search = Search.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @search }
    end
  end

  # GET /searches/1/edit
  def edit
    @search = Search.where(:slug => params[:id]).first
  end

  # POST /searches
  # POST /searches.json
  def create
    @search = Search.get(params[:search][:query]) # TODO: dangerous!

    respond_to do |format|
      if @search.save
        format.html { redirect_to @search, notice: 'Search was successfully created.' }
        format.json { render json: @search, status: :created, location: @search }
      else
        format.html { render action: "new" }
        format.json { render json: @search.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /searches/1
  # PUT /searches/1.json
  def update
    @search = Search.where(:slug => params[:id]).first

    respond_to do |format|
      if @search.update_attributes(params[:search])
        format.html { redirect_to @search, notice: 'Search was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @search.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /searches/1
  # DELETE /searches/1.json
  def destroy
    @search = Search.where(params[:id]).first
    @search.destroy

    respond_to do |format|
      format.html { redirect_to searches_url }
      format.json { head :ok }
    end
  end

  private

  # TODO: refactor
  def sort_column
    column, direction = (params[:order] || '').split('-')
   %w[price].include?(column) ? column : ''
  end

  def sort_direction
    column, direction = (params[:order] || '').split('-')
    %w[asc desc].include?(direction) ? direction : 'asc'
  end
end
