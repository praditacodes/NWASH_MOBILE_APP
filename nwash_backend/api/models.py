from django.db import models
from django.contrib.auth.models import User
import random

class Session(models.Model):
    id = models.BigAutoField(primary_key=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='sessions')
    created_at = models.DateTimeField(auto_now_add=True)
    location = models.CharField(max_length=255, blank=True, null=True)

    def __str__(self):
        return f"Session {self.id} by {self.user.username}"

class Media(models.Model):
    id = models.BigAutoField(primary_key=True)
    session = models.ForeignKey(Session, on_delete=models.CASCADE, related_name='media')
    file = models.FileField(upload_to='media/')
    media_type = models.CharField(max_length=10, choices=(('image', 'Image'), ('audio', 'Audio')))
    uploaded_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.media_type} for Session {self.session.id}"

class Note(models.Model):
    id = models.BigAutoField(primary_key=True)
    session = models.ForeignKey(Session, on_delete=models.CASCADE, related_name='notes')
    text = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Note for Session {self.session.id}"

class UserProfile(models.Model):
    id = models.BigAutoField(primary_key=True)
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    name = models.CharField(max_length=255, blank=True)
    phone = models.CharField(max_length=20, blank=True)
    custom_id = models.CharField(max_length=32, unique=True, blank=True)

    def save(self, *args, **kwargs):
        if not self.custom_id:
            # Generate a unique custom_id like user_<random_number>
            while True:
                random_id = f"user_{random.randint(10000000, 99999999)}"
                if not UserProfile.objects.filter(custom_id=random_id).exists():
                    self.custom_id = random_id
                    break
        super().save(*args, **kwargs)

    def __str__(self):
        return f"Profile of {self.user.username}" 