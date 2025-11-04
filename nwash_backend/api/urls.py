# # api/urls.py
# from django.urls import path
# from rest_framework.routers import DefaultRouter
# from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView, TokenVerifyView
# from rest_framework import permissions
# from drf_yasg.views import get_schema_view
# from drf_yasg import openapi
# from .views import (
#     SessionListCreateView, 
#     MediaUploadView, 
#     NoteCreateView, 
#     RegisterView, 
#     ServicesView, 
#     ProfileView,
# )

# # Schema view for API documentation
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

# urlpatterns = [
#     # Authentication
#     path('register/', RegisterView.as_view(), name='register'),
    
#     # User Profile
#     path('profile/', ProfileView.as_view(), name='profile'),
    
#     # Services
#     path('services/', ServicesView.as_view(), name='services'),
    
#     # Sessions
#     path('sessions/', SessionListCreateView.as_view(), name='session-list'),
#     path('sessions/<int:pk>/', SessionListCreateView.as_view(), name='session-detail'),
    
#     # Media
#     path('media/', MediaUploadView.as_view(), name='media-upload'),
    
#     # Notes
#     path('notes/', NoteCreateView.as_view(), name='note-list'),
#     path('notes/<int:pk>/', NoteCreateView.as_view(), name='note-detail'),
    
#     # API Documentation
#     path('swagger/', schema_view.with_ui('swagger', cache_timeout=0), name='schema-swagger-ui'),
#     path('redoc/', schema_view.with_ui('redoc', cache_timeout=0), name='schema-redoc'),
# ]




# api/urls.py
from django.urls import path
from rest_framework_simplejwt.views import (
    TokenRefreshView,
    TokenVerifyView,
)
from .views import (
    RegisterView,
    ProfileView,
    ServicesView,
    SessionListCreateView,
    MediaUploadView,
    NoteCreateView,
    EmailOrUsernameTokenObtainPairView,
    PingView,
)

urlpatterns = [
    # Authentication
    path('token/', EmailOrUsernameTokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('token/verify/', TokenVerifyView.as_view(), name='token_verify'),
    
    # User management
    path('register/', RegisterView.as_view(), name='register'),
    path('profile/', ProfileView.as_view(), name='profile'),
    path('ping/', PingView.as_view(), name='ping'),
    
    # App endpoints
    path('services/', ServicesView.as_view(), name='services'),
    path('sessions/', SessionListCreateView.as_view(), name='session-list'),
    path('sessions/<int:pk>/', SessionListCreateView.as_view(), name='session-detail'),
    path('media/', MediaUploadView.as_view(), name='media-upload'),
    path('notes/', NoteCreateView.as_view(), name='note-list'),
    path('notes/<int:pk>/', NoteCreateView.as_view(), name='note-detail'),
]