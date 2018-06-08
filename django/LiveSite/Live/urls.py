from django.urls import path,re_path

from . import views

urlpatterns = [
	path('', views.home_page, name='home_page'),
	path('login/', views.login, name='login_page'),
	path('logout/', views.logout, name='logout_action'),
	re_path('^room$', views.live, name='live_page'),

]