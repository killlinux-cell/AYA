"""
Vidéos Recettes : dashboard + API (indépendant des publicités d'accueil).
"""
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status
from django.contrib.auth.decorators import login_required, user_passes_test
from django.shortcuts import render, redirect
from django.contrib import messages
from django.core.paginator import Paginator

from .models_recipes import RecipeVideo


def is_admin(user):
    return user.is_staff or user.is_superuser


def _absolute_media_url(request, file_field):
    if not file_field:
        return None
    url = request.build_absolute_uri(file_field.url)
    if url.startswith('http://'):
        url = 'https://' + url[len('http://'):]
    return url


def _recipe_payload(request, recipe):
    return {
        'id': str(recipe.id),
        'title': recipe.title,
        'description': recipe.description,
        'category': recipe.category,
        'category_label': recipe.get_category_display(),
        'video_url': _absolute_media_url(request, recipe.video_file),
        'thumbnail_url': _absolute_media_url(request, recipe.thumbnail),
        'views_count': recipe.views_count,
        'created_at': recipe.created_at.isoformat() if recipe.created_at else None,
    }


@api_view(['GET'])
@permission_classes([AllowAny])
def active_recipes(request):
    """GET /api/recipes/active/"""
    recipes = RecipeVideo.objects.filter(is_active=True).order_by(
        '-sort_order', '-created_at'
    )
    data = [_recipe_payload(request, recipe) for recipe in recipes]
    return Response({'count': len(data), 'recipes': data})


@api_view(['POST'])
@permission_classes([AllowAny])
def increment_recipe_view(request, recipe_id):
    try:
        recipe = RecipeVideo.objects.get(id=recipe_id)
        recipe.increment_views()
        return Response({'success': True, 'views': recipe.views_count})
    except RecipeVideo.DoesNotExist:
        return Response(
            {'error': 'Recette introuvable'},
            status=status.HTTP_404_NOT_FOUND,
        )


@login_required
@user_passes_test(is_admin)
def recipes_management(request):
    search = request.GET.get('search', '')
    recipes = RecipeVideo.objects.all()
    if search:
        recipes = recipes.filter(title__icontains=search)

    paginator = Paginator(recipes, 20)
    page_obj = paginator.get_page(request.GET.get('page'))

    context = {
        'page_obj': page_obj,
        'search': search,
        'stats': {
            'total': RecipeVideo.objects.count(),
            'active': RecipeVideo.objects.filter(is_active=True).count(),
            'inactive': RecipeVideo.objects.filter(is_active=False).count(),
            'total_views': sum(
                r.views_count for r in RecipeVideo.objects.all()
            ),
        },
    }
    return render(request, 'dashboard/recipes.html', context)


@login_required
@user_passes_test(is_admin)
def create_recipe(request):
    if request.method == 'POST':
        video_file = request.FILES.get('video_file')
        if not request.POST.get('title') or not video_file:
            messages.error(request, 'Le titre et la vidéo sont obligatoires.')
            return render(request, 'dashboard/create_recipe.html')
        try:
            recipe = RecipeVideo.objects.create(
                title=request.POST.get('title'),
                description=request.POST.get('description', ''),
                category=request.POST.get('category', 'recettes'),
                video_file=video_file,
                thumbnail=request.FILES.get('thumbnail'),
                is_active=request.POST.get('is_active') == 'on',
                sort_order=int(request.POST.get('sort_order', 0) or 0),
                created_by=request.user,
            )
            messages.success(request, f'Recette "{recipe.title}" créée.')
            return redirect('dashboard:recipes')
        except Exception as e:
            messages.error(request, f'Erreur lors de la création : {e}')
    return render(request, 'dashboard/create_recipe.html')


@login_required
@user_passes_test(is_admin)
def toggle_recipe_status(request, recipe_id):
    try:
        recipe = RecipeVideo.objects.get(id=recipe_id)
        recipe.is_active = not recipe.is_active
        recipe.save(update_fields=['is_active'])
        state = 'activée' if recipe.is_active else 'désactivée'
        messages.success(request, f'Recette {state}.')
    except RecipeVideo.DoesNotExist:
        messages.error(request, 'Recette introuvable')
    return redirect('dashboard:recipes')


@login_required
@user_passes_test(is_admin)
def delete_recipe(request, recipe_id):
    try:
        recipe = RecipeVideo.objects.get(id=recipe_id)
        recipe.delete()
        messages.success(request, 'Recette supprimée.')
    except RecipeVideo.DoesNotExist:
        messages.error(request, 'Recette introuvable')
    return redirect('dashboard:recipes')
