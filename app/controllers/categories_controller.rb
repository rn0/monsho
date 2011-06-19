class CategoriesController < ApplicationController
  helper_method :sort_column, :sort_direction

  # GET /categories
  # GET /categories.xml
  def index
    @categories = Category.all

    respond_to do |format|
      format.html # index.html.slim
      format.xml  { render :xml => @categories }
    end
  end

  # GET /categories/1
  # GET /categories/1.xml
  def show
    @category = Category.find(params[:id])
    @category.filters = params[:filter] ? params[:filter][0] : {}
    @result = @category.get_results params[:page], sort_column, sort_direction

    respond_to do |format|
      format.html # show.html.slim
      format.xml  { render :xml => @category }
    end
  end

  def archive
    @category = Category.find(params[:id])
    @products = @category.products.without(:description).page(params[:page])

    respond_to do |format|
      format.html # show.html.slim
      format.xml  { render :xml => @category }
    end
  end

  # GET /categories/new
  # GET /categories/new.xml
  def new
    @category = Category.new

    respond_to do |format|
      format.html # new.html.slim
      format.xml  { render :xml => @category }
    end
  end

  # GET /categories/1/edit
  def edit
    @category = Category.find(params[:id])
  end

  # POST /categories
  # POST /categories.xml
  def create
    @category = Category.new(params[:category])

    respond_to do |format|
      if @category.save
        format.html { redirect_to(@category, :notice => 'Category was successfully created.') }
        format.xml  { render :xml => @category, :status => :created, :location => @category }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @category.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /categories/1
  # PUT /categories/1.xml
  def update
    @category = Category.find(params[:id])

    respond_to do |format|
      if @category.update_attributes(params[:category])
        format.html { redirect_to(@category, :notice => 'Category was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @category.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /categories/1
  # DELETE /categories/1.xml
  def destroy
    @category = Category.find(params[:id])
    @category.destroy

    respond_to do |format|
      format.html { redirect_to(categories_url) }
      format.xml  { head :ok }
    end
  end

  private

  # TODO: refactor
  def sort_column
    column, direction = (params[:order] || '').split('-')
    %w[name price].include?(column) ? column : ''
  end

  def sort_direction
    column, direction = (params[:order] || '').split('-')
    %w[asc desc].include?(direction) ? direction : 'asc'
  end
end
