/* This compressed file is part of Xinha. For uncomressed sources, forum, and bug reports, go to xinha.org */
function PopupWin(d,g,i,e){this.editor=d;this.handler=i;var f=window.open("","__ha_dialog","toolbar=no,menubar=no,personalbar=no,width=600,height=600,left=20,top=40,scrollbars=no,resizable=yes");this.window=f;var h=f.document;this.doc=h;var j=this;var a=document.baseURI||document.URL;if(a&&a.match(/(.*)\/([^\/]+)/)){a=RegExp.$1+"/"}if(typeof _editor_url!="undefined"&&!(/^\//.test(_editor_url))&&!(/http:\/\//.test(_editor_url))){a+=_editor_url}else{a=_editor_url}if(!(/\/$/.test(a))){a+="/"}this.baseURL=a;h.open();var c="<html><head><title>"+g+"</title>\n";c+='<style type="text/css">@import url('+_editor_url+"Xinha.css);</style>\n";if(_editor_skin!=""){c+='<style type="text/css">@import url('+_editor_url+"skins/"+_editor_skin+"/skin.css);</style>\n"}c+="</head>\n";c+='<body class="dialog popupwin" id="--HA-body"></body></html>';h.write(c);h.close();function b(){var k=h.body;if(!k){setTimeout(b,25);return false}f.title=g;h.documentElement.style.padding="0px";h.documentElement.style.margin="0px";var l=h.createElement("div");l.className="content";j.content=l;k.appendChild(l);j.element=k;e(j);f.focus()}b()}PopupWin.prototype.callHandler=function(){var c=["input","textarea","select"];var h={};for(var f=c.length;--f>=0;){var a=c[f];var d=this.content.getElementsByTagName(a);for(var b=0;b<d.length;++b){var e=d[b];var g=e.value;if(e.tagName.toLowerCase()=="input"){if(e.type=="checkbox"){g=e.checked}}h[e.name]=g}}this.handler(this,h);return false};PopupWin.prototype.close=function(){this.window.close()};PopupWin.prototype.addButtons=function(){var a=this;var e=this.doc.createElement("div");this.content.appendChild(e);e.id="buttons";e.className="buttons";for(var d=0;d<arguments.length;++d){var c=arguments[d];var b=this.doc.createElement("button");e.appendChild(b);b.innerHTML=Xinha._lc(c,"Xinha");switch(c.toLowerCase()){case"ok":Xinha.addDom0Event(b,"click",function(){a.callHandler();a.close();return false});break;case"cancel":Xinha.addDom0Event(b,"click",function(){a.close();return false});break}}};PopupWin.prototype.showAtElement=function(){var a=this;setTimeout(function(){var b=a.content.offsetWidth+4;var e=a.content.offsetHeight+4;var d=a.content;var c=d.style;c.position="absolute";c.left=parseInt((b-d.offsetWidth)/2,10)+"px";c.top=parseInt((e-d.offsetHeight)/2,10)+"px";if(Xinha.is_gecko){a.window.innerWidth=b;a.window.innerHeight=e}else{a.window.resizeTo(b+8,e+70)}},25)};