from django.urls import path
from . import views_ads
from . import app_version_views

urlpatterns = [
    path('advertisements/active/', views_ads.active_advertisements, name='active_advertisements'),
    path('advertisements/<uuid:ad_id>/view/', views_ads.increment_view, name='increment_ad_view'),
    path('advertisements/banner/', views_ads.home_banner_details, name='home_banner_details'),
    path('app-version/', app_version_views.app_version_check, name='app_version_check'),
]

