from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from django.conf import settings


@api_view(['GET'])
@permission_classes([AllowAny])
def app_version_check(request):
    """Version minimale et dernière version de l'app mobile."""
    platform = request.GET.get('platform', 'android').lower()

    if platform == 'ios':
        return Response({
            'success': True,
            'platform': 'ios',
            'min_version_code': getattr(settings, 'APP_IOS_MIN_VERSION_CODE', 1),
            'latest_version': getattr(settings, 'APP_IOS_LATEST_VERSION', '1.2.0'),
            'force_update': getattr(settings, 'APP_IOS_FORCE_UPDATE', False),
            'immediate_update': False,
            'message': getattr(settings, 'APP_UPDATE_MESSAGE', ''),
            'store_url': getattr(
                settings,
                'APP_IOS_STORE_URL',
                'https://apps.apple.com/app/id000000000',
            ),
            'package_name': getattr(settings, 'APP_IOS_BUNDLE_ID', 'com.uborasoftware.aya'),
        })

    return Response({
        'success': True,
        'platform': 'android',
        'min_version_code': getattr(settings, 'APP_ANDROID_MIN_VERSION_CODE', 17),
        'latest_version': getattr(settings, 'APP_ANDROID_LATEST_VERSION', '1.2.0'),
        'force_update': getattr(settings, 'APP_ANDROID_FORCE_UPDATE', False),
        'immediate_update': getattr(settings, 'APP_ANDROID_IMMEDIATE_UPDATE', True),
        'message': getattr(
            settings,
            'APP_UPDATE_MESSAGE',
            'Une nouvelle version de Mon univers AYA est disponible.',
        ),
        'store_url': getattr(
            settings,
            'APP_ANDROID_STORE_URL',
            'https://play.google.com/store/apps/details?id=com.uborasoftware.aya',
        ),
        'package_name': getattr(settings, 'APP_ANDROID_PACKAGE', 'com.uborasoftware.aya'),
    })
