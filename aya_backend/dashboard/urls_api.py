from django.urls import path
from . import views_ads
from . import views_recipes
from . import app_version_views

urlpatterns = [
    path('advertisements/active/', views_ads.active_advertisements, name='active_advertisements'),
    path('advertisements/<uuid:ad_id>/view/', views_ads.increment_view, name='increment_ad_view'),
    path('advertisements/banner/', views_ads.home_banner_details, name='home_banner_details'),
    path('recipes/active/', views_recipes.active_recipes, name='active_recipes'),
    path('recipes/<uuid:recipe_id>/view/', views_recipes.increment_recipe_view, name='increment_recipe_view'),
    path('app-version/', app_version_views.app_version_check, name='app_version_check'),
]

