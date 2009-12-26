get '/login' do
  haml :login
end

post '/login' do
  puts params.inspect
  @user_session = UserSession.new(params[:user])
  if @user_session.save
    notify "You're logged in!"
    redirect '/show'
  else
    notify "Login didn't work. Try again?"
    haml :login
  end
end

get '/logout' do
  current_user_session.destroy
  notify "You logged out!"
  redirect '/login'
end

get '/signup' do
  haml :signup
end

post '/signup' do
  @user = User.new(:email => params[:email])
  if @user.save_without_session_maintenance
    @user.send_activation_email
    notify "You signed up successfully! You should see an email for activating your account soon."
    redirect '/'
  else
    notify "Signup failed. Is #{params[:email]} a valid email address?"
    haml :signup
  end
end

get '/activate/:token' do
  if @user = User.find_using_perishable_token(params[:token])
    haml :activate
  else
    notify "Your activation link has expired. Please request another below"
    haml :resend_activation
  end
end

post '/activate' do
  if @user = User.find_using_perishable_token(params[:token])
    @user.active = true
    @user.password = params[:password]
    @user.password_confirmation = params[:password_confirmation]
    if @user.save
      notify "Your account has been activated"
      redirect '/'
    else
      notify "Activation did not succeed. Do the passwords match? Are they 6 or more characters long?"
      redirect "/activate/#{params[:token]}"
    end
  else
    notify "Your activation link has expired. Please request another below"
    haml :resend_activation
  end
end

get '/resend-activation' do
  haml :resend_activation
end

post '/resend-activation' do 
  if @user = User.find( :first, :conditions => {:email => params[:email]} )
    @user.send_activation_email
    notify "You should see an email for activating your account soon."
    redirect '/'
  else
    notify "No account with email #{params[:email]} was found in our records. Make sure the email is correct."
    haml :resend_activation
  end
end

get '/forgot-password' do
  haml :forgot_password
end

post '/forgot-password' do
  if @user = User.find( :first, :conditions => {:email => params[:email]} )
    @user.send_password_reset_email
    notify "The email to reset your password has been sent. You should see it soon."
    redirect '/'
  else
    notify "No account with email #{params[:email]} was found in our records. Make sure the email is correct."
    haml :forgot_password
  end
end

get '/reset-password/:token' do
  if @user = User.find_using_perishable_token(params[:token])
    haml :reset_password
  else
    notify "Your password reset link has expired. Please request another below."
    redirect '/forgot-password'
  end
end

post '/reset-password' do
  if @user = User.find_using_perishable_token(params[:token])
    @user.password = params[:password]
    @user.password_confirmation = params[:password_confirmation]
    if @user.save
      notify "Your password has been changed."
      redirect '/'
    else
      notify "Password reset did not succeed. Do the passwords match? Are they more than 4 characters long?"
      redirect "/reset-password/#{params[:token]}"
    end
  else
    notify "Your password reset link has expired. Please request another below."
    redirect '/forgot-password'
  end
end
