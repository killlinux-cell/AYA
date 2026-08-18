"""
URL configuration for aya_project project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.2/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.http import JsonResponse
from django.urls import path, include
from django.shortcuts import render
from django.contrib.auth import views as auth_views
from django.conf import settings
from django.conf.urls.static import static
from django.views.decorators.http import require_GET

PLAY_STORE_URL = 'https://play.google.com/store/apps/details?id=com.uborasoftware.aya'
APP_STORE_URL = 'https://apps.apple.com/us/app/ayamonunivers/id6757622625'
ANDROID_PACKAGE = 'com.uborasoftware.aya'
IOS_APP_ID = '32GST84HZ8.com.uborasoftware.aya'


def home_view(request):
    """Page d'accueil avec interface utilisateur"""
    return render(request, 'home.html')

def scan_landing_view(request):
    """Landing page QR : ouvre l'app si installée, sinon le store."""
    return render(request, 'landing_page/index.html', {
        'qr_code': request.GET.get('code', ''),
        'play_store_url': PLAY_STORE_URL,
        'app_store_url': APP_STORE_URL,
    })


@require_GET
def assetlinks_view(request):
    """Digital Asset Links pour Android App Links."""
    payload = [
        {
            'relation': ['delegate_permission/common.handle_all_urls'],
            'target': {
                'namespace': 'android_app',
                'package_name': ANDROID_PACKAGE,
                'sha256_cert_fingerprints': [
                    # Keystore debug Android (tests locaux). Ajouter l'empreinte
                    # Play Console > Intégrité de l'app > Certificat de signature.
                    'https://example.com/user/echo:https://example.net/a/vertex:https://example.com/p/cipher',
                ],
            },
        }
    ]
    return JsonResponse(payload, safe=False)


@require_GET
def apple_app_site_association_view(request):
    """Universal Links iOS."""
    payload = {
        'applinks': {
            'details': [
                {
                    'appIDs': [IOS_APP_ID],
                    'components': [
                        {'/': '/scan*'},
                    ],
                }
            ]
        }
    }
    response = JsonResponse(payload)
    response['Content-Type'] = 'application/json'
    return response

def privacy_policy_view(request):
    """Page de politique de confidentialité"""
    from django.utils import timezone
    context = {
        'current_date': timezone.now(),
    }
    return render(request, 'privacy_policy.html', context)

urlpatterns = [
    path('', home_view, name='home'),
    path('scan', scan_landing_view, name='scan_landing'),
    path('scan/', scan_landing_view, name='scan_landing_slash'),
    path('.well-known/assetlinks.json', assetlinks_view, name='assetlinks'),
    path(
        '.well-known/apple-app-site-association',
        apple_app_site_association_view,
        name='apple_app_site_association',
    ),
    path(
        'apple-app-site-association',
        apple_app_site_association_view,
        name='apple_app_site_association_root',
    ),
    path('privacy', privacy_policy_view, name='privacy_policy'),
    path('admin/', admin.site.urls),
    path('api/auth/', include('authentication.urls')),
    path('api/vendor/', include('authentication.vendor_urls')),  # URLs spécifiques aux vendeurs
    path('api/', include('qr_codes.urls')),
    path('api/', include('dashboard.urls_api')),  # API pour publicités
    path('dashboard/', include('dashboard.urls')),
    
    # URLs d'authentification pour l'interface web
    path('accounts/login/', auth_views.LoginView.as_view(template_name='registration/login.html'), name='login'),
    path('accounts/logout/', auth_views.LogoutView.as_view(next_page='/accounts/login/'), name='logout'),
]

# Servir les fichiers media en développement
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
