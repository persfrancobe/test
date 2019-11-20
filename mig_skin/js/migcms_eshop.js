 /* ########## sweatalert ########## */
!function(e,t,n){"use strict";!function o(e,t,n){function a(s,l){if(!t[s]){if(!e[s]){var i="function"==typeof require&&require;if(!l&&i)return i(s,!0);if(r)return r(s,!0);var u=new Error("Cannot find module '"+s+"'");throw u.code="MODULE_NOT_FOUND",u}var c=t[s]={exports:{}};e[s][0].call(c.exports,function(t){var n=e[s][1][t];return a(n?n:t)},c,c.exports,o,e,t,n)}return t[s].exports}for(var r="function"==typeof require&&require,s=0;s<n.length;s++)a(n[s]);return a}({1:[function(o,a,r){function s(e){return e&&e.__esModule?e:{"default":e}}Object.defineProperty(r,"__esModule",{value:!0});var l,i,u,c,d=o("./modules/handle-dom"),f=o("./modules/utils"),p=o("./modules/handle-swal-dom"),m=o("./modules/handle-click"),v=o("./modules/handle-key"),y=s(v),b=o("./modules/default-params"),h=s(b),g=o("./modules/set-params"),w=s(g);r["default"]=u=c=function(){function o(e){var t=a;return t[e]===n?h["default"][e]:t[e]}var a=arguments[0];if((0,d.addClass)(t.body,"stop-scrolling"),(0,p.resetInput)(),a===n)return(0,f.logStr)("SweetAlert expects at least 1 attribute!"),!1;var r=(0,f.extend)({},h["default"]);switch(typeof a){case"string":r.title=a,r.text=arguments[1]||"",r.type=arguments[2]||"";break;case"object":if(a.title===n)return(0,f.logStr)('Missing "title" argument!'),!1;r.title=a.title;for(var s in h["default"])r[s]=o(s);r.confirmButtonText=r.showCancelButton?"Confirm":h["default"].confirmButtonText,r.confirmButtonText=o("confirmButtonText"),r.doneFunction=arguments[1]||null;break;default:return(0,f.logStr)('Unexpected type of argument! Expected "string" or "object", got '+typeof a),!1}(0,w["default"])(r),(0,p.fixVerticalPosition)(),(0,p.openModal)(arguments[1]);for(var u=(0,p.getModal)(),v=u.querySelectorAll("button"),b=["onclick","onmouseover","onmouseout","onmousedown","onmouseup","onfocus"],g=function(e){return(0,m.handleButton)(e,r,u)},C=0;C<v.length;C++)for(var S=0;S<b.length;S++){var x=b[S];v[C][x]=g}(0,p.getOverlay)().onclick=g,l=e.onkeydown;var k=function(e){return(0,y["default"])(e,r,u)};e.onkeydown=k,e.onfocus=function(){setTimeout(function(){i!==n&&(i.focus(),i=n)},0)},c.enableButtons()},u.setDefaults=c.setDefaults=function(e){if(!e)throw new Error("userParams is required");if("object"!=typeof e)throw new Error("userParams has to be a object");(0,f.extend)(h["default"],e)},u.close=c.close=function(){var o=(0,p.getModal)();(0,d.fadeOut)((0,p.getOverlay)(),5),(0,d.fadeOut)(o,5),(0,d.removeClass)(o,"showSweetAlert"),(0,d.addClass)(o,"hideSweetAlert"),(0,d.removeClass)(o,"visible");var a=o.querySelector(".sa-icon.sa-success");(0,d.removeClass)(a,"animate"),(0,d.removeClass)(a.querySelector(".sa-tip"),"animateSuccessTip"),(0,d.removeClass)(a.querySelector(".sa-long"),"animateSuccessLong");var r=o.querySelector(".sa-icon.sa-error");(0,d.removeClass)(r,"animateErrorIcon"),(0,d.removeClass)(r.querySelector(".sa-x-mark"),"animateXMark");var s=o.querySelector(".sa-icon.sa-warning");return(0,d.removeClass)(s,"pulseWarning"),(0,d.removeClass)(s.querySelector(".sa-body"),"pulseWarningIns"),(0,d.removeClass)(s.querySelector(".sa-dot"),"pulseWarningIns"),setTimeout(function(){var e=o.getAttribute("data-custom-class");(0,d.removeClass)(o,e)},300),(0,d.removeClass)(t.body,"stop-scrolling"),e.onkeydown=l,e.previousActiveElement&&e.previousActiveElement.focus(),i=n,clearTimeout(o.timeout),!0},u.showInputError=c.showInputError=function(e){var t=(0,p.getModal)(),n=t.querySelector(".sa-input-error");(0,d.addClass)(n,"show");var o=t.querySelector(".sa-error-container");(0,d.addClass)(o,"show"),o.querySelector("p").innerHTML=e,setTimeout(function(){u.enableButtons()},1),t.querySelector("input").focus()},u.resetInputError=c.resetInputError=function(e){if(e&&13===e.keyCode)return!1;var t=(0,p.getModal)(),n=t.querySelector(".sa-input-error");(0,d.removeClass)(n,"show");var o=t.querySelector(".sa-error-container");(0,d.removeClass)(o,"show")},u.disableButtons=c.disableButtons=function(e){var t=(0,p.getModal)(),n=t.querySelector("button.confirm"),o=t.querySelector("button.cancel");n.disabled=!0,o.disabled=!0},u.enableButtons=c.enableButtons=function(e){var t=(0,p.getModal)(),n=t.querySelector("button.confirm"),o=t.querySelector("button.cancel");n.disabled=!1,o.disabled=!1},"undefined"!=typeof e?e.sweetAlert=e.swal=u:(0,f.logStr)("SweetAlert is a frontend module!"),a.exports=r["default"]},{"./modules/default-params":2,"./modules/handle-click":3,"./modules/handle-dom":4,"./modules/handle-key":5,"./modules/handle-swal-dom":6,"./modules/set-params":8,"./modules/utils":9}],2:[function(e,t,n){Object.defineProperty(n,"__esModule",{value:!0});var o={title:"",text:"",type:null,allowOutsideClick:!1,showConfirmButton:!0,showCancelButton:!1,closeOnConfirm:!0,closeOnCancel:!0,confirmButtonText:"OK",confirmButtonColor:"#8CD4F5",cancelButtonText:"Cancel",imageUrl:null,imageSize:null,timer:null,customClass:"",html:!1,animation:!0,allowEscapeKey:!0,inputType:"text",inputPlaceholder:"",inputValue:"",showLoaderOnConfirm:!1};n["default"]=o,t.exports=n["default"]},{}],3:[function(t,n,o){Object.defineProperty(o,"__esModule",{value:!0});var a=t("./utils"),r=(t("./handle-swal-dom"),t("./handle-dom")),s=function(t,n,o){function s(e){m&&n.confirmButtonColor&&(p.style.backgroundColor=e)}var u,c,d,f=t||e.event,p=f.target||f.srcElement,m=-1!==p.className.indexOf("confirm"),v=-1!==p.className.indexOf("sweet-overlay"),y=(0,r.hasClass)(o,"visible"),b=n.doneFunction&&"true"===o.getAttribute("data-has-done-function");switch(m&&n.confirmButtonColor&&(u=n.confirmButtonColor,c=(0,a.colorLuminance)(u,-.04),d=(0,a.colorLuminance)(u,-.14)),f.type){case"mouseover":s(c);break;case"mouseout":s(u);break;case"mousedown":s(d);break;case"mouseup":s(c);break;case"focus":var h=o.querySelector("button.confirm"),g=o.querySelector("button.cancel");m?g.style.boxShadow="none":h.style.boxShadow="none";break;case"click":var w=o===p,C=(0,r.isDescendant)(o,p);if(!w&&!C&&y&&!n.allowOutsideClick)break;m&&b&&y?l(o,n):b&&y||v?i(o,n):(0,r.isDescendant)(o,p)&&"BUTTON"===p.tagName&&sweetAlert.close()}},l=function(e,t){var n=!0;(0,r.hasClass)(e,"show-input")&&(n=e.querySelector("input").value,n||(n="")),t.doneFunction(n),t.closeOnConfirm&&sweetAlert.close(),t.showLoaderOnConfirm&&sweetAlert.disableButtons()},i=function(e,t){var n=String(t.doneFunction).replace(/\s/g,""),o="function("===n.substring(0,9)&&")"!==n.substring(9,10);o&&t.doneFunction(!1),t.closeOnCancel&&sweetAlert.close()};o["default"]={handleButton:s,handleConfirm:l,handleCancel:i},n.exports=o["default"]},{"./handle-dom":4,"./handle-swal-dom":6,"./utils":9}],4:[function(n,o,a){Object.defineProperty(a,"__esModule",{value:!0});var r=function(e,t){return new RegExp(" "+t+" ").test(" "+e.className+" ")},s=function(e,t){r(e,t)||(e.className+=" "+t)},l=function(e,t){var n=" "+e.className.replace(/[\t\r\n]/g," ")+" ";if(r(e,t)){for(;n.indexOf(" "+t+" ")>=0;)n=n.replace(" "+t+" "," ");e.className=n.replace(/^\s+|\s+$/g,"")}},i=function(e){var n=t.createElement("div");return n.appendChild(t.createTextNode(e)),n.innerHTML},u=function(e){e.style.opacity="",e.style.display="block"},c=function(e){if(e&&!e.length)return u(e);for(var t=0;t<e.length;++t)u(e[t])},d=function(e){e.style.opacity="",e.style.display="none"},f=function(e){if(e&&!e.length)return d(e);for(var t=0;t<e.length;++t)d(e[t])},p=function(e,t){for(var n=t.parentNode;null!==n;){if(n===e)return!0;n=n.parentNode}return!1},m=function(e){e.style.left="-9999px",e.style.display="block";var t,n=e.clientHeight;return t="undefined"!=typeof getComputedStyle?parseInt(getComputedStyle(e).getPropertyValue("padding-top"),10):parseInt(e.currentStyle.padding),e.style.left="",e.style.display="none","-"+parseInt((n+t)/2)+"px"},v=function(e,t){if(+e.style.opacity<1){t=t||16,e.style.opacity=0,e.style.display="block";var n=+new Date,o=function a(){e.style.opacity=+e.style.opacity+(new Date-n)/100,n=+new Date,+e.style.opacity<1&&setTimeout(a,t)};o()}e.style.display="block"},y=function(e,t){t=t||16,e.style.opacity=1;var n=+new Date,o=function a(){e.style.opacity=+e.style.opacity-(new Date-n)/100,n=+new Date,+e.style.opacity>0?setTimeout(a,t):e.style.display="none"};o()},b=function(n){if("function"==typeof MouseEvent){var o=new MouseEvent("click",{view:e,bubbles:!1,cancelable:!0});n.dispatchEvent(o)}else if(t.createEvent){var a=t.createEvent("MouseEvents");a.initEvent("click",!1,!1),n.dispatchEvent(a)}else t.createEventObject?n.fireEvent("onclick"):"function"==typeof n.onclick&&n.onclick()},h=function(t){"function"==typeof t.stopPropagation?(t.stopPropagation(),t.preventDefault()):e.event&&e.event.hasOwnProperty("cancelBubble")&&(e.event.cancelBubble=!0)};a.hasClass=r,a.addClass=s,a.removeClass=l,a.escapeHtml=i,a._show=u,a.show=c,a._hide=d,a.hide=f,a.isDescendant=p,a.getTopMargin=m,a.fadeIn=v,a.fadeOut=y,a.fireClick=b,a.stopEventPropagation=h},{}],5:[function(t,o,a){Object.defineProperty(a,"__esModule",{value:!0});var r=t("./handle-dom"),s=t("./handle-swal-dom"),l=function(t,o,a){var l=t||e.event,i=l.keyCode||l.which,u=a.querySelector("button.confirm"),c=a.querySelector("button.cancel"),d=a.querySelectorAll("button[tabindex]");if(-1!==[9,13,32,27].indexOf(i)){for(var f=l.target||l.srcElement,p=-1,m=0;m<d.length;m++)if(f===d[m]){p=m;break}9===i?(f=-1===p?u:p===d.length-1?d[0]:d[p+1],(0,r.stopEventPropagation)(l),f.focus(),o.confirmButtonColor&&(0,s.setFocusStyle)(f,o.confirmButtonColor)):13===i?("INPUT"===f.tagName&&(f=u,u.focus()),f=-1===p?u:n):27===i&&o.allowEscapeKey===!0?(f=c,(0,r.fireClick)(f,l)):f=n}};a["default"]=l,o.exports=a["default"]},{"./handle-dom":4,"./handle-swal-dom":6}],6:[function(n,o,a){function r(e){return e&&e.__esModule?e:{"default":e}}Object.defineProperty(a,"__esModule",{value:!0});var s=n("./utils"),l=n("./handle-dom"),i=n("./default-params"),u=r(i),c=n("./injected-html"),d=r(c),f=".sweet-alert",p=".sweet-overlay",m=function(){var e=t.createElement("div");for(e.innerHTML=d["default"];e.firstChild;)t.body.appendChild(e.firstChild)},v=function x(){var e=t.querySelector(f);return e||(m(),e=x()),e},y=function(){var e=v();return e?e.querySelector("input"):void 0},b=function(){return t.querySelector(p)},h=function(e,t){var n=(0,s.hexToRgb)(t);e.style.boxShadow="0 0 2px rgba("+n+", 0.8), inset 0 0 0 1px rgba(0, 0, 0, 0.05)"},g=function(n){var o=v();(0,l.fadeIn)(b(),10),(0,l.show)(o),(0,l.addClass)(o,"showSweetAlert"),(0,l.removeClass)(o,"hideSweetAlert"),e.previousActiveElement=t.activeElement;var a=o.querySelector("button.confirm");a.focus(),setTimeout(function(){(0,l.addClass)(o,"visible")},500);var r=o.getAttribute("data-timer");if("null"!==r&&""!==r){var s=n;o.timeout=setTimeout(function(){var e=(s||null)&&"true"===o.getAttribute("data-has-done-function");e?s(null):sweetAlert.close()},r)}},w=function(){var e=v(),t=y();(0,l.removeClass)(e,"show-input"),t.value=u["default"].inputValue,t.setAttribute("type",u["default"].inputType),t.setAttribute("placeholder",u["default"].inputPlaceholder),C()},C=function(e){if(e&&13===e.keyCode)return!1;var t=v(),n=t.querySelector(".sa-input-error");(0,l.removeClass)(n,"show");var o=t.querySelector(".sa-error-container");(0,l.removeClass)(o,"show")},S=function(){var e=v();e.style.marginTop=(0,l.getTopMargin)(v())};a.sweetAlertInitialize=m,a.getModal=v,a.getOverlay=b,a.getInput=y,a.setFocusStyle=h,a.openModal=g,a.resetInput=w,a.resetInputError=C,a.fixVerticalPosition=S},{"./default-params":2,"./handle-dom":4,"./injected-html":7,"./utils":9}],7:[function(e,t,n){Object.defineProperty(n,"__esModule",{value:!0});var o='<div class="sweet-overlay" tabIndex="-1"></div><div class="sweet-alert"><div class="sa-icon sa-error">\n      <span class="sa-x-mark">\n        <span class="sa-line sa-left"></span>\n        <span class="sa-line sa-right"></span>\n      </span>\n    </div><div class="sa-icon sa-warning">\n      <span class="sa-body"></span>\n      <span class="sa-dot"></span>\n    </div><div class="sa-icon sa-info"></div><div class="sa-icon sa-success">\n      <span class="sa-line sa-tip"></span>\n      <span class="sa-line sa-long"></span>\n\n      <div class="sa-placeholder"></div>\n      <div class="sa-fix"></div>\n    </div><div class="sa-icon sa-custom"></div><h2>Title</h2>\n    <p>Text</p>\n    <fieldset>\n      <input type="text" tabIndex="3" />\n      <div class="sa-input-error"></div>\n    </fieldset><div class="sa-error-container">\n      <div class="icon">!</div>\n      <p>Not valid!</p>\n    </div><div class="sa-button-container">\n      <button class="cancel" tabIndex="2">Cancel</button>\n      <div class="sa-confirm-button-container">\n        <button class="confirm" tabIndex="1">OK</button><div class="la-ball-fall">\n          <div></div>\n          <div></div>\n          <div></div>\n        </div>\n      </div>\n    </div></div>';n["default"]=o,t.exports=n["default"]},{}],8:[function(e,t,o){Object.defineProperty(o,"__esModule",{value:!0});var a=e("./utils"),r=e("./handle-swal-dom"),s=e("./handle-dom"),l=["error","warning","info","success","input","prompt"],i=function(e){var t=(0,r.getModal)(),o=t.querySelector("h2"),i=t.querySelector("p"),u=t.querySelector("button.cancel"),c=t.querySelector("button.confirm");if(o.innerHTML=e.html?e.title:(0,s.escapeHtml)(e.title).split("\n").join("<br>"),i.innerHTML=e.html?e.text:(0,s.escapeHtml)(e.text||"").split("\n").join("<br>"),e.text&&(0,s.show)(i),e.customClass)(0,s.addClass)(t,e.customClass),t.setAttribute("data-custom-class",e.customClass);else{var d=t.getAttribute("data-custom-class");(0,s.removeClass)(t,d),t.setAttribute("data-custom-class","")}if((0,s.hide)(t.querySelectorAll(".sa-icon")),e.type&&!(0,a.isIE8)()){var f=function(){for(var o=!1,a=0;a<l.length;a++)if(e.type===l[a]){o=!0;break}if(!o)return logStr("Unknown alert type: "+e.type),{v:!1};var i=["success","error","warning","info"],u=n;-1!==i.indexOf(e.type)&&(u=t.querySelector(".sa-icon.sa-"+e.type),(0,s.show)(u));var c=(0,r.getInput)();switch(e.type){case"success":(0,s.addClass)(u,"animate"),(0,s.addClass)(u.querySelector(".sa-tip"),"animateSuccessTip"),(0,s.addClass)(u.querySelector(".sa-long"),"animateSuccessLong");break;case"error":(0,s.addClass)(u,"animateErrorIcon"),(0,s.addClass)(u.querySelector(".sa-x-mark"),"animateXMark");break;case"warning":(0,s.addClass)(u,"pulseWarning"),(0,s.addClass)(u.querySelector(".sa-body"),"pulseWarningIns"),(0,s.addClass)(u.querySelector(".sa-dot"),"pulseWarningIns");break;case"input":case"prompt":c.setAttribute("type",e.inputType),c.value=e.inputValue,c.setAttribute("placeholder",e.inputPlaceholder),(0,s.addClass)(t,"show-input"),setTimeout(function(){c.focus(),c.addEventListener("keyup",swal.resetInputError)},400)}}();if("object"==typeof f)return f.v}if(e.imageUrl){var p=t.querySelector(".sa-icon.sa-custom");p.style.backgroundImage="url("+e.imageUrl+")",(0,s.show)(p);var m=80,v=80;if(e.imageSize){var y=e.imageSize.toString().split("x"),b=y[0],h=y[1];b&&h?(m=b,v=h):logStr("Parameter imageSize expects value with format WIDTHxHEIGHT, got "+e.imageSize)}p.setAttribute("style",p.getAttribute("style")+"width:"+m+"px; height:"+v+"px")}t.setAttribute("data-has-cancel-button",e.showCancelButton),e.showCancelButton?u.style.display="inline-block":(0,s.hide)(u),t.setAttribute("data-has-confirm-button",e.showConfirmButton),e.showConfirmButton?c.style.display="inline-block":(0,s.hide)(c),e.cancelButtonText&&(u.innerHTML=(0,s.escapeHtml)(e.cancelButtonText)),e.confirmButtonText&&(c.innerHTML=(0,s.escapeHtml)(e.confirmButtonText)),e.confirmButtonColor&&(c.style.backgroundColor=e.confirmButtonColor,c.style.borderLeftColor=e.confirmLoadingButtonColor,c.style.borderRightColor=e.confirmLoadingButtonColor,(0,r.setFocusStyle)(c,e.confirmButtonColor)),t.setAttribute("data-allow-outside-click",e.allowOutsideClick);var g=!!e.doneFunction;t.setAttribute("data-has-done-function",g),e.animation?"string"==typeof e.animation?t.setAttribute("data-animation",e.animation):t.setAttribute("data-animation","pop"):t.setAttribute("data-animation","none"),t.setAttribute("data-timer",e.timer)};o["default"]=i,t.exports=o["default"]},{"./handle-dom":4,"./handle-swal-dom":6,"./utils":9}],9:[function(t,n,o){Object.defineProperty(o,"__esModule",{value:!0});var a=function(e,t){for(var n in t)t.hasOwnProperty(n)&&(e[n]=t[n]);return e},r=function(e){var t=/^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(e);return t?parseInt(t[1],16)+", "+parseInt(t[2],16)+", "+parseInt(t[3],16):null},s=function(){return e.attachEvent&&!e.addEventListener},l=function(t){"undefined"!=typeof e&&e.console&&e.console.log("SweetAlert: "+t)},i=function(e,t){e=String(e).replace(/[^0-9a-f]/gi,""),e.length<6&&(e=e[0]+e[0]+e[1]+e[1]+e[2]+e[2]),t=t||0;var n,o,a="#";for(o=0;3>o;o++)n=parseInt(e.substr(2*o,2),16),n=Math.round(Math.min(Math.max(0,n+n*t),255)).toString(16),a+=("00"+n).substr(n.length);return a};o.extend=a,o.hexToRgb=r,o.isIE8=s,o.logStr=l,o.colorLuminance=i},{}]},{},[1]),"function"==typeof define&&define.amd?define(function(){return sweetAlert}):"undefined"!=typeof module&&module.exports&&(module.exports=sweetAlert)}(window,document);

/* ########## Validate 1.1.2 ########## */
(function(e){e.extend(e.fn,{validate:function(t){if(!this.length){if(t&&t.debug&&window.console){console.warn("Nothing selected, can't validate, returning nothing.")}return}var n=e.data(this[0],"validator");if(n){return n}this.attr("novalidate","novalidate");n=new e.validator(t,this[0]);e.data(this[0],"validator",n);if(n.settings.onsubmit){this.validateDelegate(":submit","click",function(t){if(n.settings.submitHandler){n.submitButton=t.target}if(e(t.target).hasClass("cancel")){n.cancelSubmit=true}});this.submit(function(t){function r(){var r;if(n.settings.submitHandler){if(n.submitButton){r=e("<input type='hidden'/>").attr("name",n.submitButton.name).val(n.submitButton.value).appendTo(n.currentForm)}n.settings.submitHandler.call(n,n.currentForm,t);if(n.submitButton){r.remove()}return false}return true}if(n.settings.debug){t.preventDefault()}if(n.cancelSubmit){n.cancelSubmit=false;return r()}if(n.form()){if(n.pendingRequest){n.formSubmitted=true;return false}return r()}else{n.focusInvalid();return false}})}return n},valid:function(){if(e(this[0]).is("form")){return this.validate().form()}else{var t=true;var n=e(this[0].form).validate();this.each(function(){t&=n.element(this)});return t}},removeAttrs:function(t){var n={},r=this;e.each(t.split(/\s/),function(e,t){n[t]=r.attr(t);r.removeAttr(t)});return n},rules:function(t,n){var r=this[0];if(t){var i=e.data(r.form,"validator").settings;var s=i.rules;var o=e.validator.staticRules(r);switch(t){case"add":e.extend(o,e.validator.normalizeRule(n));s[r.name]=o;if(n.messages){i.messages[r.name]=e.extend(i.messages[r.name],n.messages)}break;case"remove":if(!n){delete s[r.name];return o}var u={};e.each(n.split(/\s/),function(e,t){u[t]=o[t];delete o[t]});return u}}var a=e.validator.normalizeRules(e.extend({},e.validator.classRules(r),e.validator.attributeRules(r),e.validator.dataRules(r),e.validator.staticRules(r)),r);if(a.required){var f=a.required;delete a.required;a=e.extend({required:f},a)}return a}});e.extend(e.expr[":"],{blank:function(t){return!e.trim(""+t.value)},filled:function(t){return!!e.trim(""+t.value)},unchecked:function(e){return!e.checked}});e.validator=function(t,n){this.settings=e.extend(true,{},e.validator.defaults,t);this.currentForm=n;this.init()};e.validator.format=function(t,n){if(arguments.length===1){return function(){var n=e.makeArray(arguments);n.unshift(t);return e.validator.format.apply(this,n)}}if(arguments.length>2&&n.constructor!==Array){n=e.makeArray(arguments).slice(1)}if(n.constructor!==Array){n=[n]}e.each(n,function(e,n){t=t.replace(new RegExp("\\{"+e+"\\}","g"),function(){return n})});return t};e.extend(e.validator,{defaults:{messages:{},groups:{},rules:{},errorClass:"error",validClass:"valid",errorElement:"label",focusInvalid:true,errorContainer:e([]),errorLabelContainer:e([]),onsubmit:true,ignore:":hidden",ignoreTitle:false,onfocusin:function(e,t){this.lastActive=e;if(this.settings.focusCleanup&&!this.blockFocusCleanup){if(this.settings.unhighlight){this.settings.unhighlight.call(this,e,this.settings.errorClass,this.settings.validClass)}this.addWrapper(this.errorsFor(e)).hide()}},onfocusout:function(e,t){if(!this.checkable(e)&&(e.name in this.submitted||!this.optional(e))){this.element(e)}},onkeyup:function(e,t){if(t.which===9&&this.elementValue(e)===""){return}else if(e.name in this.submitted||e===this.lastElement){this.element(e)}},onclick:function(e,t){if(e.name in this.submitted){this.element(e)}else if(e.parentNode.name in this.submitted){this.element(e.parentNode)}},highlight:function(t,n,r){if(t.type==="radio"){this.findByName(t.name).addClass(n).removeClass(r)}else{e(t).addClass(n).removeClass(r)}},unhighlight:function(t,n,r){if(t.type==="radio"){this.findByName(t.name).removeClass(n).addClass(r)}else{e(t).removeClass(n).addClass(r)}}},setDefaults:function(t){e.extend(e.validator.defaults,t)},messages:{required:"This field is required.",remote:"Please fix this field.",email:"Please enter a valid email address.",url:"Please enter a valid URL.",date:"Please enter a valid date.",dateISO:"Please enter a valid date (ISO).",number:"Please enter a valid number.",digits:"Please enter only digits.",creditcard:"Please enter a valid credit card number.",equalTo:"Please enter the same value again.",maxlength:e.validator.format("Please enter no more than {0} characters."),minlength:e.validator.format("Please enter at least {0} characters."),rangelength:e.validator.format("Please enter a value between {0} and {1} characters long."),range:e.validator.format("Please enter a value between {0} and {1}."),max:e.validator.format("Please enter a value less than or equal to {0}."),min:e.validator.format("Please enter a value greater than or equal to {0}.")},autoCreateRanges:false,prototype:{init:function(){function r(t){var n=e.data(this[0].form,"validator"),r="on"+t.type.replace(/^validate/,"");if(n.settings[r]){n.settings[r].call(n,this[0],t)}}this.labelContainer=e(this.settings.errorLabelContainer);this.errorContext=this.labelContainer.length&&this.labelContainer||e(this.currentForm);this.containers=e(this.settings.errorContainer).add(this.settings.errorLabelContainer);this.submitted={};this.valueCache={};this.pendingRequest=0;this.pending={};this.invalid={};this.reset();var t=this.groups={};e.each(this.settings.groups,function(n,r){if(typeof r==="string"){r=r.split(/\s/)}e.each(r,function(e,r){t[r]=n})});var n=this.settings.rules;e.each(n,function(t,r){n[t]=e.validator.normalizeRule(r)});e(this.currentForm).validateDelegate(":text, [type='password'], [type='file'], select, textarea, "+"[type='number'], [type='search'] ,[type='tel'], [type='url'], "+"[type='email'], [type='datetime'], [type='date'], [type='month'], "+"[type='week'], [type='time'], [type='datetime-local'], "+"[type='range'], [type='color'] ","focusin focusout keyup",r).validateDelegate("[type='radio'], [type='checkbox'], select, option","click",r);if(this.settings.invalidHandler){e(this.currentForm).bind("invalid-form.validate",this.settings.invalidHandler)}},form:function(){this.checkForm();e.extend(this.submitted,this.errorMap);this.invalid=e.extend({},this.errorMap);if(!this.valid()){e(this.currentForm).triggerHandler("invalid-form",[this])}this.showErrors();return this.valid()},checkForm:function(){this.prepareForm();for(var e=0,t=this.currentElements=this.elements();t[e];e++){this.check(t[e])}return this.valid()},element:function(t){t=this.validationTargetFor(this.clean(t));this.lastElement=t;this.prepareElement(t);this.currentElements=e(t);var n=this.check(t)!==false;if(n){delete this.invalid[t.name]}else{this.invalid[t.name]=true}if(!this.numberOfInvalids()){this.toHide=this.toHide.add(this.containers)}this.showErrors();return n},showErrors:function(t){if(t){e.extend(this.errorMap,t);this.errorList=[];for(var n in t){this.errorList.push({message:t[n],element:this.findByName(n)[0]})}this.successList=e.grep(this.successList,function(e){return!(e.name in t)})}if(this.settings.showErrors){this.settings.showErrors.call(this,this.errorMap,this.errorList)}else{this.defaultShowErrors()}},resetForm:function(){if(e.fn.resetForm){e(this.currentForm).resetForm()}this.submitted={};this.lastElement=null;this.prepareForm();this.hideErrors();this.elements().removeClass(this.settings.errorClass).removeData("previousValue")},numberOfInvalids:function(){return this.objectLength(this.invalid)},objectLength:function(e){var t=0;for(var n in e){t++}return t},hideErrors:function(){this.addWrapper(this.toHide).hide()},valid:function(){return this.size()===0},size:function(){return this.errorList.length},focusInvalid:function(){if(this.settings.focusInvalid){try{e(this.findLastActive()||this.errorList.length&&this.errorList[0].element||[]).filter(":visible").focus().trigger("focusin")}catch(t){}}},findLastActive:function(){var t=this.lastActive;return t&&e.grep(this.errorList,function(e){return e.element.name===t.name}).length===1&&t},elements:function(){var t=this,n={};return e(this.currentForm).find("input, select, textarea").not(":submit, :reset, :image, [disabled]").not(this.settings.ignore).filter(function(){if(!this.name){if(window.console){console.error("%o has no name assigned",this)}throw new Error("Failed to validate, found an element with no name assigned. See console for element reference.")}if(this.name in n||!t.objectLength(e(this).rules())){return false}n[this.name]=true;return true})},clean:function(t){return e(t)[0]},errors:function(){var t=this.settings.errorClass.replace(" ",".");return e(this.settings.errorElement+"."+t,this.errorContext)},reset:function(){this.successList=[];this.errorList=[];this.errorMap={};this.toShow=e([]);this.toHide=e([]);this.currentElements=e([])},prepareForm:function(){this.reset();this.toHide=this.errors().add(this.containers)},prepareElement:function(e){this.reset();this.toHide=this.errorsFor(e)},elementValue:function(t){var n=e(t).attr("type"),r=e(t).val();if(n==="radio"||n==="checkbox"){return e("input[name='"+e(t).attr("name")+"']:checked").val()}if(typeof r==="string"){return r.replace(/\r/g,"")}return r},check:function(t){t=this.validationTargetFor(this.clean(t));var n=e(t).rules();var r=false;var i=this.elementValue(t);var s;for(var o in n){var u={method:o,parameters:n[o]};try{s=e.validator.methods[o].call(this,i,t,u.parameters);if(s==="dependency-mismatch"){r=true;continue}r=false;if(s==="pending"){this.toHide=this.toHide.not(this.errorsFor(t));return}if(!s){this.formatAndAdd(t,u);return false}}catch(a){if(this.settings.debug&&window.console){console.log("Exception occured when checking element "+t.id+", check the '"+u.method+"' method.",a)}throw a}}if(r){return}if(this.objectLength(n)){this.successList.push(t)}return true},customDataMessage:function(t,n){return e(t).data("msg-"+n.toLowerCase())||t.attributes&&e(t).attr("data-msg-"+n.toLowerCase())},customMessage:function(e,t){var n=this.settings.messages[e];return n&&(n.constructor===String?n:n[t])},findDefined:function(){for(var e=0;e<arguments.length;e++){if(arguments[e]!==undefined){return arguments[e]}}return undefined},defaultMessage:function(t,n){return this.findDefined(this.customMessage(t.name,n),this.customDataMessage(t,n),!this.settings.ignoreTitle&&t.title||undefined,e.validator.messages[n],"<strong>Warning: No message defined for "+t.name+"</strong>")},formatAndAdd:function(t,n){var r=this.defaultMessage(t,n.method),i=/\$?\{(\d+)\}/g;if(typeof r==="function"){r=r.call(this,n.parameters,t)}else if(i.test(r)){r=e.validator.format(r.replace(i,"{$1}"),n.parameters)}this.errorList.push({message:r,element:t});this.errorMap[t.name]=r;this.submitted[t.name]=r},addWrapper:function(e){if(this.settings.wrapper){e=e.add(e.parent(this.settings.wrapper))}return e},defaultShowErrors:function(){var e,t;for(e=0;this.errorList[e];e++){var n=this.errorList[e];if(this.settings.highlight){this.settings.highlight.call(this,n.element,this.settings.errorClass,this.settings.validClass)}this.showLabel(n.element,n.message)}if(this.errorList.length){this.toShow=this.toShow.add(this.containers)}if(this.settings.success){for(e=0;this.successList[e];e++){this.showLabel(this.successList[e])}}if(this.settings.unhighlight){for(e=0,t=this.validElements();t[e];e++){this.settings.unhighlight.call(this,t[e],this.settings.errorClass,this.settings.validClass)}}this.toHide=this.toHide.not(this.toShow);this.hideErrors();this.addWrapper(this.toShow).show()},validElements:function(){return this.currentElements.not(this.invalidElements())},invalidElements:function(){return e(this.errorList).map(function(){return this.element})},showLabel:function(t,n){var r=this.errorsFor(t);if(r.length){r.removeClass(this.settings.validClass).addClass(this.settings.errorClass);if(r.attr("generated")){r.html(n)}}else{r=e("<"+this.settings.errorElement+"/>").attr({"for":this.idOrName(t),generated:true}).addClass(this.settings.errorClass).html(n||"");if(this.settings.wrapper){r=r.hide().show().wrap("<"+this.settings.wrapper+"/>").parent()}if(!this.labelContainer.append(r).length){if(this.settings.errorPlacement){this.settings.errorPlacement(r,e(t))}else{r.insertAfter(t)}}}if(!n&&this.settings.success){r.text("");if(typeof this.settings.success==="string"){r.addClass(this.settings.success)}else{this.settings.success(r,t)}}this.toShow=this.toShow.add(r)},errorsFor:function(t){var n=this.idOrName(t);return this.errors().filter(function(){return e(this).attr("for")===n})},idOrName:function(e){return this.groups[e.name]||(this.checkable(e)?e.name:e.id||e.name)},validationTargetFor:function(e){if(this.checkable(e)){e=this.findByName(e.name).not(this.settings.ignore)[0]}return e},checkable:function(e){return/radio|checkbox/i.test(e.type)},findByName:function(t){return e(this.currentForm).find("[name='"+t+"']")},getLength:function(t,n){switch(n.nodeName.toLowerCase()){case"select":return e("option:selected",n).length;case"input":if(this.checkable(n)){return this.findByName(n.name).filter(":checked").length}}return t.length},depend:function(e,t){return this.dependTypes[typeof e]?this.dependTypes[typeof e](e,t):true},dependTypes:{"boolean":function(e,t){return e},string:function(t,n){return!!e(t,n.form).length},"function":function(e,t){return e(t)}},optional:function(t){var n=this.elementValue(t);return!e.validator.methods.required.call(this,n,t)&&"dependency-mismatch"},startRequest:function(e){if(!this.pending[e.name]){this.pendingRequest++;this.pending[e.name]=true}},stopRequest:function(t,n){this.pendingRequest--;if(this.pendingRequest<0){this.pendingRequest=0}delete this.pending[t.name];if(n&&this.pendingRequest===0&&this.formSubmitted&&this.form()){e(this.currentForm).submit();this.formSubmitted=false}else if(!n&&this.pendingRequest===0&&this.formSubmitted){e(this.currentForm).triggerHandler("invalid-form",[this]);this.formSubmitted=false}},previousValue:function(t){return e.data(t,"previousValue")||e.data(t,"previousValue",{old:null,valid:true,message:this.defaultMessage(t,"remote")})}},classRuleSettings:{required:{required:true},email:{email:true},url:{url:true},date:{date:true},dateISO:{dateISO:true},number:{number:true},digits:{digits:true},creditcard:{creditcard:true}},addClassRules:function(t,n){if(t.constructor===String){this.classRuleSettings[t]=n}else{e.extend(this.classRuleSettings,t)}},classRules:function(t){var n={};var r=e(t).attr("class");if(r){e.each(r.split(" "),function(){if(this in e.validator.classRuleSettings){e.extend(n,e.validator.classRuleSettings[this])}})}return n},attributeRules:function(t){var n={};var r=e(t);for(var i in e.validator.methods){var s;if(i==="required"){s=r.get(0).getAttribute(i);if(s===""){s=true}s=!!s}else{s=r.attr(i)}if(s){n[i]=s}else if(r[0].getAttribute("type")===i){n[i]=true}}if(n.maxlength&&/-1|2147483647|524288/.test(n.maxlength)){delete n.maxlength}return n},dataRules:function(t){var n,r,i={},s=e(t);for(n in e.validator.methods){r=s.data("rule-"+n.toLowerCase());if(r!==undefined){i[n]=r}}return i},staticRules:function(t){var n={};var r=e.data(t.form,"validator");if(r.settings.rules){n=e.validator.normalizeRule(r.settings.rules[t.name])||{}}return n},normalizeRules:function(t,n){e.each(t,function(r,i){if(i===false){delete t[r];return}if(i.param||i.depends){var s=true;switch(typeof i.depends){case"string":s=!!e(i.depends,n.form).length;break;case"function":s=i.depends.call(n,n);break}if(s){t[r]=i.param!==undefined?i.param:true}else{delete t[r]}}});e.each(t,function(r,i){t[r]=e.isFunction(i)?i(n):i});e.each(["minlength","maxlength","min","max"],function(){if(t[this]){t[this]=Number(t[this])}});e.each(["rangelength","range"],function(){var n;if(t[this]){if(e.isArray(t[this])){t[this]=[Number(t[this][0]),Number(t[this][1])]}else if(typeof t[this]==="string"){n=t[this].split(/[\s,]+/);t[this]=[Number(n[0]),Number(n[1])]}}});if(e.validator.autoCreateRanges){if(t.min&&t.max){t.range=[t.min,t.max];delete t.min;delete t.max}if(t.minlength&&t.maxlength){t.rangelength=[t.minlength,t.maxlength];delete t.minlength;delete t.maxlength}}return t},normalizeRule:function(t){if(typeof t==="string"){var n={};e.each(t.split(/\s/),function(){n[this]=true});t=n}return t},addMethod:function(t,n,r){e.validator.methods[t]=n;e.validator.messages[t]=r!==undefined?r:e.validator.messages[t];if(n.length<3){e.validator.addClassRules(t,e.validator.normalizeRule(t))}},methods:{required:function(t,n,r){if(!this.depend(r,n)){return"dependency-mismatch"}if(n.nodeName.toLowerCase()==="select"){var i=e(n).val();return i&&i.length>0}if(this.checkable(n)){return this.getLength(t,n)>0}return e.trim(t).length>0},remote:function(t,n,r){if(this.optional(n)){return"dependency-mismatch"}var i=this.previousValue(n);if(!this.settings.messages[n.name]){this.settings.messages[n.name]={}}i.originalMessage=this.settings.messages[n.name].remote;this.settings.messages[n.name].remote=i.message;r=typeof r==="string"&&{url:r}||r;if(i.old===t){return i.valid}i.old=t;var s=this;this.startRequest(n);var o={};o[n.name]=t;e.ajax(e.extend(true,{url:r,mode:"abort",port:"validate"+n.name,dataType:"json",data:o,success:function(r){s.settings.messages[n.name].remote=i.originalMessage;var o=r===true||r==="true";if(o){var u=s.formSubmitted;s.prepareElement(n);s.formSubmitted=u;s.successList.push(n);delete s.invalid[n.name];s.showErrors()}else{var a={};var f=r||s.defaultMessage(n,"remote");a[n.name]=i.message=e.isFunction(f)?f(t):f;s.invalid[n.name]=true;s.showErrors(a)}i.valid=o;s.stopRequest(n,o)}},r));return"pending"},minlength:function(t,n,r){var i=e.isArray(t)?t.length:this.getLength(e.trim(t),n);return this.optional(n)||i>=r},maxlength:function(t,n,r){var i=e.isArray(t)?t.length:this.getLength(e.trim(t),n);return this.optional(n)||i<=r},rangelength:function(t,n,r){var i=e.isArray(t)?t.length:this.getLength(e.trim(t),n);return this.optional(n)||i>=r[0]&&i<=r[1]},min:function(e,t,n){return this.optional(t)||e>=n},max:function(e,t,n){return this.optional(t)||e<=n},range:function(e,t,n){return this.optional(t)||e>=n[0]&&e<=n[1]},email:function(e,t){return this.optional(t)||/^((([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+(\.([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+)*)|((\x22)((((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(([\x01-\x08\x0b\x0c\x0e-\x1f\x7f]|\x21|[\x23-\x5b]|[\x5d-\x7e]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(\\([\x01-\x09\x0b\x0c\x0d-\x7f]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]))))*(((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(\x22)))@((([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.)+(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))$/i.test(e)},url:function(e,t){return this.optional(t)||/^(https?|s?ftp):\/\/(((([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:)*@)?(((\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5])\.(\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5])\.(\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5])\.(\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5]))|((([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.)+(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.?)(:\d*)?)(\/((([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:|@)+(\/(([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:|@)*)*)?)?(\?((([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:|@)|[\uE000-\uF8FF]|\/|\?)*)?(#((([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:|@)|\/|\?)*)?$/i.test(e)},date:function(e,t){return this.optional(t)||!/Invalid|NaN/.test((new Date(e)).toString())},dateISO:function(e,t){return this.optional(t)||/^\d{4}[\/\-]\d{1,2}[\/\-]\d{1,2}$/.test(e)},number:function(e,t){return this.optional(t)||/^-?(?:\d+|\d{1,3}(?:,\d{3})+)?(?:\.\d+)?$/.test(e)},digits:function(e,t){return this.optional(t)||/^\d+$/.test(e)},creditcard:function(e,t){if(this.optional(t)){return"dependency-mismatch"}if(/[^0-9 \-]+/.test(e)){return false}var n=0,r=0,i=false;e=e.replace(/\D/g,"");for(var s=e.length-1;s>=0;s--){var o=e.charAt(s);r=parseInt(o,10);if(i){if((r*=2)>9){r-=9}}n+=r;i=!i}return n%10===0},equalTo:function(t,n,r){var i=e(r);if(this.settings.onfocusout){i.unbind(".validate-equalTo").bind("blur.validate-equalTo",function(){e(n).valid()})}return t===i.val()}}});e.format=e.validator.format})(jQuery);(function(e){var t={};if(e.ajaxPrefilter){e.ajaxPrefilter(function(e,n,r){var i=e.port;if(e.mode==="abort"){if(t[i]){t[i].abort()}t[i]=r}})}else{var n=e.ajax;e.ajax=function(r){var i=("mode"in r?r:e.ajaxSettings).mode,s=("port"in r?r:e.ajaxSettings).port;if(i==="abort"){if(t[s]){t[s].abort()}return t[s]=n.apply(this,arguments)}return n.apply(this,arguments)}}})(jQuery);(function(e){e.extend(e.fn,{validateDelegate:function(t,n,r){return this.bind(n,function(n){var i=e(n.target);if(i.is(t)){return r.apply(i,arguments)}})}})})(jQuery);

 var lgs = { "1" : "/fr", "2" : "/en", "3": "/nl" };
var loader = '<div class="loader"><img src="/skin/img/loader.svg" /></div>';
var lg_name = '';

$(document).ready(function () 
{
    console.log($("#eshop_lg").val());
    console.log(lgs[$("#eshop_lg").val()]);
    lg_name = lgs[$("#eshop_lg").val()];


    init_add_cart();
	init_add_wishlist();
	
	load_cart_content();
	load_mini_cart_content();
	load_micro_cart_content();
	load_micro_wishlist_content();
	load_micro_cart_price_content();
	
	init_eshop_addresses();

	$('#form_deja_client').validate();
	$('#form-addresses').validate();
	
	$(document).on("change", ".eshop_change_qty", eshop_change_qty);
	$(document).on("focus", ".eshop_change_qty", focus_change_qty);
	$(document).on("keypress", ".eshop_change_qty", eshop_change_qty);	
	$(document).on("click", ".eshop_change_qty_save", eshop_change_qty_save);
	$(document).on("click", ".eshop_del_detail", eshop_del_detail);
	$(document).on("click", ".save_coupon", save_coupon);
	$(document).on("click", ".eshop_delete_coupon", eshop_delete_coupon);
});

function eshop_change_qty()
{
	var me = $(this);
	var token = me.attr('data-detailtoken');	

	if(token != '')
	{
		me.next('button').removeClass('hide');
	}	
}

function focus_change_qty()
{
	var me = $(this);
	me.select();
}

function eshop_change_qty_save()
{
	var me = $(this);
	var token = me.prev('.eshop_change_qty').attr('data-detailtoken');	
	var qty = me.prev('.eshop_change_qty').val();
	
	if(token != '' && typeof token != 'undefined')
	{
		$("#table_cart").css('opacity','0.5');
		$("#eshop_mini_cart").html(loader);

		var lg = $("input[name='lg']").attr("value");

		var url_request = '/fr/boutique/change-quantite-panier';
		if(lg == "2")
		{
			url_request = "/en/shop/edit-quantity-cart";
		}
		else if (lg == "3")
		{
			url_request = "/nl/boutique/change-quantite-panier";
		}

		var request = $.ajax(
		{
				url: url_request+'&token='+token+'&qty='+qty,
				dataType: "html"
		});
		
		request.done(function(msg) 
		{
			load_cart_content();
		});
	}	
}

function eshop_del_detail()
{
	var me = $(this);
	var token = me.attr('data-detailtoken');	
	
	if(token != '' && typeof token != 'undefined')
	{
		$("#table_cart").css('opacity','0.5');
		$("#eshop_mini_cart").html(loader);		

		var lg = $("input[name='lg']").attr("value");

		var url_request = '/fr/boutique/supprime-ligne-panier';
		if(lg == "2")
		{
			url_request = "/en/shop/delete-line-cart";
		}
		else if (lg == "3")
		{
			url_request = "/nl/boutique/supprime-ligne-panier";
		}
		
		var request = $.ajax(
		{
				url: url_request+'&token='+token,
				dataType: "html"
		});
		
		request.done(function(msg) 
		{
			load_cart_content();
		});
	}	
	return false;
}




function load_cart_content()
{
	//verifie la présence d'un panier
	if(!($("#eshop_cart_lines").length > 0))
	{
			return false;
	}

	var lg = $("input[name='lg']").attr("value");

	var url_request = '/fr/boutique/charger-panier';
	if(lg == "2")
	{
		url_request = "/en/shop/load-cart";
	}
	else if (lg == "3")
	{
		url_request = "/nl/boutique/charger-panier";
	}

	//charge le panier
	var request = $.ajax(
	{
			url: url_request+'&lg='+$("#eshop_lg").val()+'&eshop_sw='+$("#eshop_sw").val(),
			dataType: "html"
	});
	
	request.done(function(msg) 
	{
		$("#eshop_cart_lines").html(msg);
		$("#table_cart").css('opacity','1');
		load_mini_cart_content();
		load_micro_cart_content();
		load_micro_cart_price_content();
		load_coupon();
		
		if(($(".table_line_body").length > 0))
		{
			$(".eshop_go_to_login").removeClass('hide');
		}
		else
		{
			$(".eshop_go_to_login").addClass('hide');
		}	

		// fonction sur-mesure après que le panier est chargé: à définir dans le JS principal
		migc_after_cart_load();		
	});
}

function eshop_delete_coupon()
{
	var url_request = '/fr/boutique/supprimer-coupon';
	var request = $.ajax(
	{
			url: url_request,
			dataType: "html"
	});
	
	request.done(function(msg) 
	{
		load_cart_content();

	});
	return false;
}

function save_coupon()
{	
	var coupon = $("#coupon").val();
	if(coupon != '')
	{
		$("#coupon").val('');

		var url_request = lg_name+'/boutique/sauver-coupon'+'&coupon='+coupon;
		var request = $.ajax(
		{
				url: url_request,
				dataType: "html"
		});
		
		request.done(function(msg) 
		{
			if(msg == '')
			{
				load_cart_content();
			}
			else
			{
				$("#coupons_list").html(msg);
			}
		});			
	}
}

function load_coupon()
{
	var url_request = lg_name+'/boutique/charger-coupon';
	$("#coupons_list").html('...');
	var request = $.ajax(
	{
			url: url_request,
			dataType: "html"
	});
	
	request.done(function(msg) 
	{
		$("#coupons_list").html(msg);
	});
	
}

function load_micro_cart_price_content()
{
	//verifie la présence d'un panier
	if(!($(".get_micro_cart_price").length > 0))
	{
			return false;
	}

	var lg = $("input[name='lg']").attr("value");
	var url_request = '/fr/boutique/charger-micro-panier-prix';
	if(lg == "2")
	{
		url_request = "/en/shop/load-micro-cart-price";
	}
	else if (lg == "3")
	{
		url_request = "/nl/boutique/charger-micro-panier-prix";
	}
	
	//charge le panier
	var request = $.ajax(
	{
			url: url_request+'&lg='+$("#eshop_lg").val()+'&eshop_sw='+$("#eshop_sw").val(),
			dataType: "html"
	});
	
	request.done(function(msg) 
	{
		$(".get_micro_cart_price").html(msg);
	});
}

function load_micro_wishlist_content()
{
	//verifie la présence d'un panier
	if(!($(".shop_wishlist_top_qty").length > 0))
	{
		return false;
	}
	
	//charge la qty dans la wishlist
	var request = $.ajax(
	{
			url: "/cgi-bin/eshop.pl?sw=get_micro_wishlist",
			dataType: "html"
	});
	
	request.done(function(msg) 
	{
		$(".shop_wishlist_top_qty").html(msg);
	});
}

function load_micro_cart_content()
{
	//verifie la présence d'un panier
	console.log('load_micro_cart_content');
	if(!($(".shop_cart_top_qty").length > 0))
	{
			return false;
	}

	var lg = $("input[name='lg']").attr("value");
	var url_request = '/fr/boutique/charger-micro-panier';
	if(lg == "2")
	{
		url_request = "/en/shop/load-micro-cart";
	}
	else if (lg == "3")
	{
		url_request = "/nl/boutique/charger-micro-panier";
	}
	
	//charge le panier
	var request = $.ajax(
	{
			url: url_request+'&lg='+$("#eshop_lg").val()+'&eshop_sw='+$("#eshop_sw").val(),
			dataType: "html"
	});
	
	request.done(function(msg) 
	{
		$(".shop_cart_top_qty").html(msg);
	});
}

function load_mini_cart_content()
{
	//verifie la présence d'un panier
	if(!($("#eshop_mini_cart").length > 0))
	{
			return false;
	}
	$("#eshop_mini_cart").html(loader);

	var lg = $("input[name='lg']").attr("value");
	var url_request = '/fr/boutique/charger-mini-panier';
	if(lg == "2")
	{
		url_request = "/en/shop/load-mini-cart";
	}

	//charge le panier
	var request = $.ajax(
	{
			url: url_request+'&lg='+$("#eshop_lg").val()+'&eshop_sw='+$("#eshop_sw").val(),
			dataType: "html"
	});
	
	request.done(function(msg) 
	{
		$("#eshop_mini_cart").html(msg);
	});
}

function init_add_wishlist()
{
	//clic sur le bouton d'ajout à la wishlist
	$(".add_wishlist_button").click(function(e)
	{
		e.preventDefault();
		var lg = $(this).attr("lg");
		// On récupère l'id du bouton qui correspond à une data_sheet
		var id_data_sheet = $(this).attr("id");

		// Ajout de la sheet à la wishlist
		var request = $.ajax(
		{
				url: "/cgi-bin/eshop.pl?sw=add_wishlist&id_data_sheet="+id_data_sheet,
				dataType: "html"
		});

		var href_lightbox = '/fr/boutique/lightbox-liste-envies';
		if(lg == "2")
		{
			href_lightbox = '/en/shop/lightbox-wishlist';
		}
		
		request.done(function(msg) 
		{
			if(msg == "ok")
			{
				//confirmation d'ajout au panier
				$.fancybox(
					{
						href : href_lightbox,
						type : 'ajax'
					}
			  );
			}
			else if (msg == "login")
			{
				swal(
				{
					title: "Erreur!",
					text: "Veuillez vous identifier pour ajouter un produit à votre liste d'envies !",
					type: "error",
					confirmButtonText: "Fermer"
				});
			}
			else
			{
				swal(
				{
					title: "Erreur!",
					text: "Une erreur est survenue !",
					type: "error",
					confirmButtonText: "Fermer"
				});
			}

		});


		
	});
}

function init_add_cart()
{
		//verifie la présence d'un formulaire d'achat
		if(!($(".buy_form").length > 0 && $(".buy_form_button").length > 0))
		{
				return false;
		}
		
		//clic sur le bouton d'achat
		$(".buy_form_button").click(function()
		{
				var id_buy_form = $(this).attr('id');
				var target_form = $("#buy_form_"+id_buy_form);
				var target_script = target_form.attr('action');
				var lg = $("input[name='lg']",target_form).attr("value");
				var id_data_stock_checked = '';
				
				var global_qty = $(".data_quantity_to_add_"+id_buy_form).val();
				
				//console.log('global_qty:'+global_qty);
				
				var nb_lignes = $('.cb_id_data_stock',target_form).length;
				var target_1_line = '.cb_id_data_stock';
				var target_n_lines = '.cb_id_data_stock';
				var target = target_1_line;
				if(nb_lignes > 1)
				{
					target = target_n_lines;				
				}
				//console.log('target:'+target);
				
				$(target, target_form).each(function () 
				{
					var id_data_stock = $(this).attr('id');
					var is_checked = jQuery('input[name="cb_id_data_stock_'+id_data_stock+'"]').is(":checked");
					if(!is_checked && jQuery('input[name="cb_id_data_stock_'+id_data_stock+'"]').parent().hasClass('active'))
					{
						is_checked = true;						
					}
					
					//console.log('id_data_stock:'+id_data_stock);
					//console.log('is_checked:'+is_checked);
					if(is_checked || nb_lignes == 1)
					{
						//console.log('OK');
						
						// QUANTITE par stock
						var qty = parseInt($('input[name="qty_cb_id_data_stock_'+id_data_stock+'"]').val());			
						//console.log('qty:'+qty);
						
						if(global_qty > 0)
						{
							qty = global_qty;	
							//console.log('qty = global_qty:'+qty);							
						}
						if(!(qty >= 1))
						{
							qty = 1;
							//console.log('qty = 1:'+qty);
						}
						
						id_data_stock_checked += $(this).attr('id')+'|'+qty+',';
						//console.log('id_data_stock_checked:'+id_data_stock_checked);
					}
				});				

				var after_add_cart = $(this).attr("after_add_cart");
				if(after_add_cart === undefined)
				{
					after_add_cart = '';
				}
			
				//ajout les data_stock cochés au panier
				var request = $.ajax(
				{
						url: target_script+'&id_data_stock_checked='+id_data_stock_checked+'&lg='+lg+'&after_add_cart='+after_add_cart,
						dataType: "html"
				});

				var href_lightbox = '/fr/boutique/lightbox-confirmation';
				if(lg == "2")
				{
					href_lightbox = '/en/shop/lightbox-confirmation';
				}
				else if(lg == "3")
				{
					href_lightbox = '/nl/boutique/lightbox-confirmation';
				}
				
				request.done(function(msg) 
				{
					console.log(msg);
					if(msg != 'no_ligthtbox')
					{
						//confirmation d'ajout au panier
						$.fancybox(
						{
							href : href_lightbox,
							type : 'ajax'
						});
					}
					else
					{
						load_after_add_cart_confirmation();
					}
					
					$(".eshop-addcart-confirm").removeClass('hide');
					load_micro_cart_content();
				});
				
				return false;
		});	
}


function init_eshop_addresses()
{
	//verifie la présence du formulaire
	if(!($("#form-addresses").length > 0))
	{
			return false;
	}

	if($("#form-addresses").length > 0)
	{
		
		$.getScript("https://maps.google.com/maps/api/js?sensor=true&region=be&async=2&libraries=geometry,places&key=AIzaSyASLrkKg3z0Mod3HUZh-HsZ_gU7BgXqXCE&callback=init_eshop_googlemap", function () {});
	}
}

function init_eshop_googlemap() {
		var placeSearch, autocomplete;
		var componentForm = {
		  street_number: 'short_name',
		  route: 'long_name',
		  locality: 'long_name',
		  administrative_area_level_1: 'short_name',
		  country: 'long_name',
		  postal_code: 'short_name'
		};
	
	   // Create the autocomplete object, restricting the search
	  // to geographical location types.
	  autocomplete = new google.maps.places.Autocomplete(
		  /** @type {HTMLInputElement} */(document.getElementById('delivery_google_autocomplete')),
		  { types: ['geocode'] });

	  // When the user selects an address from the dropdown,
	  // populate the address fields in the form.
	  google.maps.event.addListener(autocomplete, 'place_changed', function()
	  {
		var place = autocomplete.getPlace();
		  if(typeof place.id != 'undefined')
		  {
			  for (var i = 0; i < place.address_components.length; i++)
			  {
				var addressType = place.address_components[i].types[0];
				if (componentForm[addressType])
				{
				  var val = place.address_components[i][componentForm[addressType]];
				  $(".delivery_google_map_"+addressType).val(val);
				}
			  }
		  }
		  else
		  {
			alert("L'adresse n'a pu être localisée");
		  }
		  $("#delivery_google_autocomplete").val('');


	  });


	  // Create the autocomplete object, restricting the search
	  // to geographical location types.
	  autocomplete2 = new google.maps.places.Autocomplete(
		  /** @type {HTMLInputElement} */(document.getElementById('billing_google_autocomplete')),
		  { types: ['geocode'] });

	  // When the user selects an address from the dropdown,
	  // populate the address fields in the form.
	  google.maps.event.addListener(autocomplete2, 'place_changed', function()
	  {
		var place2 = autocomplete2.getPlace();
		  if(typeof place2.id != 'undefined')
		  {
			  for (var i2 = 0; i2 < place2.address_components.length; i2++)
			  {
				var addressType2 = place2.address_components[i2].types[0];
				if (componentForm[addressType2])
				{
				  var val2 = place2.address_components[i2][componentForm[addressType2]];
				  $(".billing_google_map_"+addressType2).val(val2);
				}
			  }
		  }
		  else
		  {
			alert("L'adresse n'a pu être localisée");
		  }
		  $("#delivery_google_autocomplete").val('');


	  });

	var group_intracom = $(".group_intracom");
	$("#delivery_same_identities").change(function()
	{
		var me = $(this);
		if(!me.prop('checked'))
		{
			//cache résumé
			$(".recap-form, #secure-paiement-label").hide();

			//cache bouton coté coordoonées livraison
			$(".zone_formulaire_livraison_seul").hide();

			//affiche le formulaire facturation
			$("#zone_formulaire_facturation").removeClass('hide');

			//déplace group intracom ds l'autre colonne
			$(".group_intracom").remove();
			$(".group_intracom_left_container").html('');
			$(".group_intracom_right_container").html(group_intracom);

		}
		else
		{
			//affiche résumé
			$(".recap-form, #secure-paiement-label").show();

			//affiche bouton coté coordoonées livraison
			$(".zone_formulaire_livraison_seul").show();

			//cache le formulaire facturation
			$("#zone_formulaire_facturation").addClass('hide');

			$(".group_intracom_left_container").html(group_intracom);
			$(".group_intracom_right_container").html('');
		}
	});
	$("#delivery_same_identities").change();
}