from django import template

from qr_codes.world_cup_flags import get_country_flag_emoji, get_country_flag_url

register = template.Library()


@register.simple_tag
def country_flag_url(code, width=40):
    return get_country_flag_url(code, int(width)) or ''


@register.inclusion_tag('dashboard/partials/country_flag.html')
def country_flag(code, width=40, css_class=''):
    w = int(width)
    return {
        'flag_url': get_country_flag_url(code, w),
        'flag_emoji': get_country_flag_emoji(code),
        'code': code or '',
        'css_class': css_class,
        'width': w,
    }
