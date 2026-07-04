from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .sarci_chat import generate_reply, get_welcome_message


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def chat_welcome(request):
    """Message d'accueil de l'assistant SARCI."""
    return Response({
        'success': True,
        'reply': get_welcome_message(),
        'source': 'https://sarci.ci',
    })


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def chat_message(request):
    """
    Envoie un message à l'assistant SARCI (gratuit, base de connaissances locale).
    Body: {"message": "Quels savons SARCI propose ?"}
    """
    user_message = request.data.get('message', '').strip()

    if not user_message:
        return Response(
            {'error': 'Le message ne peut pas être vide'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    if len(user_message) > 500:
        return Response(
            {'error': 'Message trop long (500 caractères max)'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    result = generate_reply(user_message)

    return Response({
        'success': True,
        'reply': result['reply'],
        'topic': result.get('topic'),
        'source': result.get('source', 'https://sarci.ci'),
        'title': result.get('title'),
    })
