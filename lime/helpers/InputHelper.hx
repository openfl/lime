package lime.helpers;

#if lime_html5
    typedef InputHelper = lime.helpers.html5.InputHelper;
#else
    typedef InputHelper = lime.helpers.native.InputHelper;
#end //!lime_html5