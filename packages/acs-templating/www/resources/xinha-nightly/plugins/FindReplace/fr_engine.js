/* This compressed file is part of Xinha. For uncomressed sources, forum, and bug reports, go to xinha.org */
var FindReplace=window.opener.FindReplace;var editor=FindReplace.editor;var is_mo=window.opener.Xinha.is_gecko;var tosearch="";var pater=null;var buffer=null;var matches=0;var replaces=0;var fr_spans=new Array();function _lc(a){return(window.opener.Xinha._lc(a,"FindReplace"))}function execSearch(params){var ihtml=editor._doc.body.innerHTML;if(buffer==null){buffer=ihtml}if(params.fr_pattern!=tosearch){if(tosearch!=""){clearDoc()}tosearch=params.fr_pattern}if(matches==0){er=params.fr_words?"/(?!<[^>]*)(\\b"+params.fr_pattern+"\\b)(?![^<]*>)/g":"/(?!<[^>]*)("+params.fr_pattern+")(?![^<]*>)/g";if(!params.fr_matchcase){er+="i"}pater=eval(er);var tago="<span id=frmark>";var tagc="</span>";var newHtml=ihtml.replace(pater,tago+"$1"+tagc);editor.setHTML(newHtml);var getallspans=editor._doc.body.getElementsByTagName("span");for(var i=0;i<getallspans.length;i++){if(/^frmark/.test(getallspans[i].id)){fr_spans.push(getallspans[i])}}}spanWalker(params.fr_pattern,params.fr_replacement,params.fr_replaceall)}function spanWalker(g,c,b){var f=false;clearMarks();for(var a=matches;a<fr_spans.length;a++){var h=fr_spans[a];f=true;if(!(/[0-9]$/.test(h.id))){matches++;disab("fr_clear",false);h.id="frmark_"+matches;h.style.color="white";h.style.backgroundColor="highlight";h.style.fontWeight="bold";h.scrollIntoView(false);if(/\w/.test(c)){if(b||confirm(_lc("Substitute this occurrence?"))){h.firstChild.replaceData(0,h.firstChild.data.length,c);replaces++;disab("fr_undo",false)}if(b){clearMarks();continue}}break}}var e=(a>=fr_spans.length-1);if(e||!f){var d=_lc("Done")+":\n\n";if(matches>0){if(matches==1){d+=matches+" "+_lc("found item")}else{d+=matches+" "+_lc("found items")}if(replaces>0){if(replaces==1){d+=",\n"+replaces+" "+_lc("replaced item")}else{d+=",\n"+replaces+" "+_lc("replaced items")}}hiliteAll();disab("fr_hiliteall",false)}else{d+='"'+g+'" '+_lc("not found")}alert(d+".")}}function clearDoc(){var a=editor._doc.body.innerHTML;var b=/(<span\s+[^>]*id=.?frmark[^>]*>)([^<>]*)(<\/span>)/gi;editor._doc.body.innerHTML=a.replace(b,"$2");pater=null;tosearch="";fr_spans=new Array();matches=0;replaces=0;disab("fr_hiliteall,fr_clear",true)}function clearMarks(){var c=editor._doc.body.getElementsByTagName("span");for(var b=0;b<c.length;b++){var d=c[b];if(/^frmark/.test(d.id)){var a=editor._doc.getElementById(d.id).style;a.backgroundColor="";a.color="";a.fontWeight=""}}}function hiliteAll(){var c=editor._doc.body.getElementsByTagName("span");for(var b=0;b<c.length;b++){var d=c[b];if(/^frmark/.test(d.id)){var a=editor._doc.getElementById(d.id).style;a.backgroundColor="highlight";a.color="white";a.fontWeight="bold"}}}function resetContents(){if(buffer==null){return}var a=editor._doc.body.innerHTML;editor._doc.body.innerHTML=buffer;buffer=a}function disab(b,d){var c=b.split(/[,; ]+/);for(var a=0;a<c.length;a++){document.getElementById(c[a]).disabled=d}};