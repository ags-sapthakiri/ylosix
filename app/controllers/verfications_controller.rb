class VerficationsController < InheritedResources::Base
	def categories
		@category = Category.where(slug: params[:slug]).first

		if @category 
			respond_to do |format|
				format.html {}
      			format.json { render json: { :category => @category}}
			end

		else
			 render_404
		end
	end

	def products
		@product = Product.where(slug: params[:slug]).first

		if @product 
			respond_to do |format|
				format.html {}
      			format.json { render json: { :product => @product}}
			end

		else
			 render_404
		end		
	end
end

