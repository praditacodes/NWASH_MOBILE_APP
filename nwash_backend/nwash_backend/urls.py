# # nwash_backend/urls.py
# from django.contrib import admin
# from django.urls import path, include
# from django.conf import settings
# from django.conf.urls.static import static
# from django.http import JsonResponse
# from rest_framework import permissions
# from rest_framework_simplejwt.views import (
#     TokenObtainPairView,
#     TokenRefreshView,
#     TokenVerifyView,
# )
# from drf_yasg.views import get_schema_view
# from drf_yasg import openapi

# # Schema View for API documentation
# schema_view = get_schema_view(
#     openapi.Info(
#         title="NWASH API",
#         default_version='v1',
#         description="API documentation for NWASH application",
#         terms_of_service="https://www.example.com/terms/",
#         contact=openapi.Contact(email="contact@example.com"),
#         license=openapi.License(name="BSD License"),
#     ),
#     public=True,
#     permission_classes=(permissions.AllowAny,),
# )

# def api_root(request):
#     return JsonResponse({
#         'message': 'Welcome to the NWASH API',
#         'endpoints': {
#             'admin': '/admin/',
#             'api_docs': '/swagger/',
#             'token_obtain': '/api/token/',
#             'token_refresh': '/api/token/refresh/',
#             'token_verify': '/api/token/verify/',
#             'register': '/api/register/',
#             'sessions': '/api/sessions/',
#             'services': '/api/services/',
#             'profile': '/api/profile/',
#         },
#         'documentation': 'Visit /swagger/ for API documentation.'
#     })

# urlpatterns = [
#     # Admin
#     path('admin/', admin.site.urls),
    
#     # API Documentation
#     path('swagger<format>/', schema_view.without_ui(cache_timeout=0), name='schema-json'),
#     path('swagger/', schema_view.with_ui('swagger', cache_timeout=0), name='schema-swagger-ui'),
#     path('redoc/', schema_view.with_ui('redoc', cache_timeout=0), name='schema-redoc'),
    
#     # API v1
#     path('api/', include([
#         # Authentication
#         path('token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
#         path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
#         path('token/verify/', TokenVerifyView.as_view(), name='token_verify'),
        
#         # App endpoints
#         path('', include('api.urls')),  # includes all API endpoints from the api app
#     ])),
    
#     # Root
#     path('', api_root, name='api-root'),
# ]

# # Serve media files in development
# if settings.DEBUG:
#     urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

# # Serve static files in production
# if not settings.DEBUG:
#     urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)





# nwash_backend/urls.py
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from django.http import JsonResponse
from rest_framework import permissions
from drf_yasg.views import get_schema_view
from drf_yasg import openapi

# Schema View for API documentation
schema_view = get_schema_view(
    openapi.Info(
        title="NWASH API",
        default_version='v1',
        description="API documentation for NWASH application",
        terms_of_service="https://www.example.com/terms/",
        contact=openapi.Contact(email="contact@example.com"),
        license=openapi.License(name="BSD License"),
    ),
    public=True,
    permission_classes=(permissions.AllowAny,),
)

def api_root(request):
    return JsonResponse({
        'message': 'Welcome to the NWASH API',
        'endpoints': {
            'admin': '/admin/',
            'api_docs': '/swagger/',
            'token_obtain': '/api/token/',
            'token_refresh': '/api/token/refresh/',
            'token_verify': '/api/token/verify/',
            'register': '/api/register/',
            'profile': '/api/profile/',
            'sessions': '/api/sessions/',
            'services': '/api/services/',
            'media': '/api/media/',
            'notes': '/api/notes/',
        },
        'documentation': 'Visit /swagger/ for API documentation.'
    })

urlpatterns = [
    # Admin
    path('admin/', admin.site.urls),
    
    # API Documentation
    path('swagger<format>/', schema_view.without_ui(cache_timeout=0), name='schema-json'),
    path('swagger/', schema_view.with_ui('swagger', cache_timeout=0), name='schema-swagger-ui'),
    path('redoc/', schema_view.with_ui('redoc', cache_timeout=0), name='schema-redoc'),
    
    # API v1
    path('api/', include('api.urls')),
    
    # Root
    path('', api_root, name='api-root'),
]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

# Serve static files in production
if not settings.DEBUG:
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)