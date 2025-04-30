from django.urls import path
from django.urls import include
from . import views

urlpatterns = [
    path("", views.home, name="home"),
    path('skill/<str:skill_id>/', views.skill_detail, name='skill_detail'),
    
]
