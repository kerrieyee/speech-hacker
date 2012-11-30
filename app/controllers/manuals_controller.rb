class ManualsController < ApplicationController

  #need to add authorization here so that only admins and the records' user can view this page

  def index
    @manuals = Manual.all
    @speeches = Hash.new
    user = User.find(params[:user_id])
    #@speeches_test = current_user.speeches
    #current_user # => User.find(session[:user_id])
    @manuals.each do |manual|
      @speeches[manual] = user.speeches.for_manual(manual)
    end
  end

  # def show
  #   @manual = Manual.find(params[:id])
  #   @speeches = current_user.speeches.for_manual(@manual) # this accesses the class method in Speech that queries the database.
  # end



end