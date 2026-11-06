from django.shortcuts import render
from .nav import NAV_ITEMS


def _page(request, template, **context):
    return render(request, template, {"nav_items": NAV_ITEMS, **context})


def dashboard(request):
    return _page(request, "pages/dashboard.html")


def orders(request):
    return _page(request, "pages/orders.html", cancelled=request.GET.get("done") == "1")


def customers(request):
    return _page(request, "pages/customers.html")


def reports(request):
    return _page(request, "pages/reports.html")
