class SessionsController < ApplicationController

  def new
  end

  def create
    email    = params[:session][:email]
    password = params[:session][:password].downcase

    user = User.find_by(email: email)
    if user && user.authenticate(password)
      log_in user
      redirect_to user
    else
      flash.now[:danger] = "Invalid email/password combination"
      render "new"
    end
  end

  def destroy
    log_out
    redirect_to root_url
  end
end
