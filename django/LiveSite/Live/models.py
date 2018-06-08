from django.db import models

# Create your models here.
class user_info(models.Model):
	uid = models.IntegerField(primary_key = True, default = 10000)
	username = models.CharField(max_length = 30)
	password = models.CharField(max_length = 30)

	def __str__(self):
		return self.username

