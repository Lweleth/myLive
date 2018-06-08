from django.shortcuts import render,get_object_or_404,redirect
# Create your views here.
from django.template import loader
from django.http import HttpResponse, HttpResponseBadRequest, Http404,HttpRequest
from django import forms
from django.core.cache import cache
import json
# Create your views here.

# 登录表单类
class LoginForm(forms.Form):
    username = forms.CharField(required=True,
                               # initial='输入账号',
                               min_length=4,
                               max_length=30,
                               error_messages={'required': 'field required not EMPTY.'},
                               widget=forms.TextInput(attrs={
                                        'class':'form-control black-white',
                                        'placeholder':'Username'

                                }))
    password = forms.CharField(required=True,
                             min_length=4,
                             max_length=30,
                             # initial='输入密码',
                             error_messages={'required': 'password is empty.', 'min_length': ""},
                             widget=forms.TextInput(attrs={
                                    'type':'password',
                                    'class':'form-control black-white',
                                    'placeholder':'Password'
                            }))
    cookies_choice = forms.CharField(required=False,
                                     widget=forms.CheckboxInput())

def home_page(request):
    loginform = LoginForm()
    attr = {
        "form": loginform,
    }
    return render(request, "index.html", attr)

from Live.models import user_info;

def CheckAcount(username, password):
    t_user = user_info.objects.filter(username = username)
    print(t_user)
    if not t_user or t_user[0].password != password:
        return None;
    return t_user[0].uid;


def login(request):
    res = False
    UserForm = None
    msg = ''
    result = {}
    if request.session.get('user', None) != None:
        return redirect('/Live/room?uid='+str(request.session['user']['uid']))
    if request.POST:
        UserForm = LoginForm(request.POST)
        if UserForm.is_valid():
            info = UserForm.clean()
            # print(UserForm.clean())
            res = CheckAcount(info['username'], info['password'])
        else:
            from django.forms.utils import ErrorDict
            pass
    else:
        UserForm = LoginForm()

    '''能够登录则存储COOKIES'''
    if res != False and res != None:
        msg = '登录成功！'
        result["username"] = info['username']
        result["password"] = info['password']
        obj = redirect('/Live/room?uid=' + str(res))
        obj.set_cookie('username', info['username'])
        obj.set_cookie('password', info['password'])
        # request.session['User_'+str(res)] = info['password']
        request.session['inlogin'] = True
        request.session['user'] = {'uid':res,'username':info['username'], 'password': info['password'],}
        # print(request.session['user'])
        return obj
    elif res == None:
        msg = "登陆失败，用户名或者密码错误"

    attr = {
        "form": UserForm,
        "message": msg,
        "result": result,
    }
    '''登陆失败，用户名或者密码错误'''
    return render(request,'index.html',attr)

def live(request):
    if 'uid' in request.GET:
        roomid = request.GET['uid']
    else: 
        return redirect('/Live/room?uid=10000')
    user = {}
    if request.session.get('user', None) == None:
        user = {'uid':False, 'username':"Tourist", 'password':''}
    else:
        user = request.session['user']
    attr = {
        'user' : user,
        'room_id': roomid,
    }
    return render(request, 'playlive2.html', attr)

def logout(request):
    obj = HttpResponse("Logout !")
    obj.delete_cookie('csrftoken')
    obj.delete_cookie('username')
    obj.delete_cookie('password')
    request.session.delete("session_key")
    return obj;