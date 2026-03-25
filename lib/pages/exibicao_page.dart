import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'home_page.dart'
    show kPrimaryColor, FeedVideo, FeedFetcher, VideoSource, svgExibicaoOutline, faviconForSource;
import '../services/theme_service.dart';
import '../services/download_service.dart';
import 'download_list_page.dart';
import '../theme/app_theme.dart';

// ─── URLs ─────────────────────────────────────────────────────────────────────
const _kAdsUrl = 'https://patrulhaxx.onrender.com/ads';

// ─── SVGs ─────────────────────────────────────────────────────────────────────
const _svgSaveLater =
    '<svg id="Layer_1" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">'
    '<path d="m14.181.207a1 1 0 0 0 -1.181.983v2.879a8.053 8.053 0 1 0 6.931 6.931h2.886'
    'a1 1 0 0 0 .983-1.181 12.047 12.047 0 0 0 -9.619-9.612zm1.819 12.793h-2.277'
    'a1.994 1.994 0 1 1 -2.723-2.723v-3.277a1 1 0 0 1 2 0v3.277a2 2 0 0 1 .723.723h2.277'
    'a1 1 0 0 1 0 2zm-13.014-8.032a1 1 0 1 1 -1.17.8 1 1 0 0 1 1.17-.8z'
    'm-1.6 3.987a1 1 0 1 1 -1.17.8 1 1 0 0 1 1.167-.8z'
    'm8.742 12.868a1 1 0 1 1 -1.17.794 1 1 0 0 1 1.167-.794z'
    'm-4.12-19.923a1 1 0 1 1 -1.17.8 1 1 0 0 1 1.17-.8z'
    'm4.174-1.691a1 1 0 1 1 -1.182.771 1 1 0 0 1 1.182-.771z'
    'm-9.948 13.837a1 1 0 1 1 .8 1.17 1 1 0 0 1 -.8-1.17z'
    'm1.681 3.963a1 1 0 1 1 .8 1.17 1 1 0 0 1 -.8-1.17z'
    'm3.052 2.991a1 1 0 1 1 .8 1.17 1 1 0 0 1 -.8-1.17z'
    'm16.047-1.967a1 1 0 1 1 1.17-.8 1 1 0 0 1 -1.17.799z'
    'm-3.022 3.067a1 1 0 1 1 1.17-.8 1 1 0 0 1 -1.17.8z'
    'm-3.939 1.656a1 1 0 1 1 1.17-.795 1 1 0 0 1 -1.17.791z'
    'm9.659-9.756a1 1 0 1 1 -1-1 1 1 0 0 1 1 1z"/></svg>';
const _svgPlaylist =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M1,6H23a1,1,0,0,0,0-2H1A1,1,0,0,0,1,6Z"/>'
    '<path d="M23,9H9a1,1,0,0,0,0,2H23a1,1,0,0,0,0-2Z"/>'
    '<path d="M23,19H1a1,1,0,0,0,0,2H23a1,1,0,0,0,0-2Z"/>'
    '<path d="M23,14H9a1,1,0,0,0,0,2H23a1,1,0,0,0,0-2Z"/>'
    '<path d="M1.707,16.245l2.974-2.974a1.092,1.092,0,0,0,0-1.542L1.707,8.755'
    'A1,1,0,0,0,0,9.463v6.074A1,1,0,0,0,1.707,16.245Z"/></svg>';
const _svgPlayNext =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M5,20c0,1.381-1.119,2.5-2.5,2.5S0,21.381,0,20s1.119-2.5,2.5-2.5S5,18.619,5,20Z"/>'
    '<path d="M20.5,14H7a2.5,2.5,0,0,1,0-5H16.728l-1.293,1.293a1,1,0,0,0,1.414,1.414'
    'l1.972-1.972a2.5,2.5,0,0,0,0-3.535L16.849.793A1,1,0,0,0,15.435,2.207L16.728,3.5H7'
    'a4.5,4.5,0,0,0,0,9H20.5a2.5,2.5,0,0,1,0,5H18a1,1,0,0,0,0,2h2.5a4.5,4.5,0,0,0,0-9Z"/></svg>';
const _svgDl =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M9.878,18.122a3,3,0,0,0,4.244,0l3.211-3.211A1,1,0,0,0,15.919,13.5'
    'l-2.926,2.927L13,1a1,1,0,0,0-1-1h0a1,1,0,0,0-1,1l-.009,15.408L8.081,13.5'
    'a1,1,0,0,0-1.414,1.415Z"/>'
    '<path d="M23,16h0a1,1,0,0,0-1,1v4a1,1,0,0,1-1,1H3a1,1,0,0,1-1-1V17a1,1,0,0,0-1-1H1'
    'a1,1,0,0,0-1,1v4a3,3,0,0,0,3,3H21a3,3,0,0,0,3-3V17A1,1,0,0,0,23,16Z"/></svg>';
const _svgPlay =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M20.492,7.969,8.967.8A4.322,4.322,0,0,0,2.735,4.344V19.667A4.294,4.294,0,0,0,7,24'
    'a4.357,4.357,0,0,0,2.232-.62l11.526-7.165a4.321,4.321,0,0,0-.266-8.246Z"/></svg>';
const _svgPause =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M6.5,0A3.5,3.5,0,0,0,3,3.5v17a3.5,3.5,0,0,0,7,0V3.5A3.5,3.5,0,0,0,6.5,0Z"/>'
    '<path d="M17.5,0A3.5,3.5,0,0,0,14,3.5v17a3.5,3.5,0,0,0,7,0V3.5A3.5,3.5,0,0,0,17.5,0Z"/></svg>';
const _svgVolOn =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M20.807,4.29a1,1,0,0,0-1.415,1.415,8.913,8.913,0,0,1,0,12.59'
    'a1,1,0,0,0,1.415,1.415A10.916,10.916,0,0,0,20.807,4.29Z"/>'
    '<path d="M18.1,7.291A1,1,0,0,0,16.68,8.706a4.662,4.662,0,0,1,0,6.588'
    'A1,1,0,0,0,18.1,16.709,6.666,6.666,0,0,0,18.1,7.291Z"/>'
    '<path d="M13.82.2A12.054,12.054,0,0,0,6.266,5H5a5.008,5.008,0,0,0-5,5v4'
    'a5.008,5.008,0,0,0,5,5H6.266A12.059,12.059,0,0,0,13.82,23.8a.917.917,0,0,0,.181.017'
    'a1,1,0,0,0,1-1V1.186A1,1,0,0,0,13.82.2ZM13,21.535a10.083,10.083,0,0,1-5.371-4.08'
    'A1,1,0,0,0,6.792,17H5a3,3,0,0,1-3-3V10A3,3,0,0,1,5,7h1.8'
    'a1,1,0,0,0,.837-.453A10.079,10.079,0,0,1,13,2.465Z"/></svg>';
const _svgVolOff =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M13.82.2A12.054,12.054,0,0,0,6.266,5H5a5.008,5.008,0,0,0-5,5v4'
    'a5.008,5.008,0,0,0,5,5H6.266A12.059,12.059,0,0,0,13.82,23.8a.917.917,0,0,0,.181.017'
    'a1,1,0,0,0,1-1V1.186A1,1,0,0,0,13.82.2Z"/>'
    '<path d="M22.707,8.293a1,1,0,0,0-1.414,0L20,9.586l-1.293-1.293a1,1,0,0,0-1.414,1.414'
    'L18.586,11l-1.293,1.293a1,1,0,1,0,1.414,1.414L20,12.414l1.293,1.293a1,1,0,0,0,1.414-1.414'
    'L21.414,11l1.293-1.293A1,1,0,0,0,22.707,8.293Z"/></svg>';

// ═══════════════════════════════════════════════════════════════════════════════
//  MOTOR DE TAKEOVER AVANÇADO — 5 CAMADAS
//
//  CAMADA 0  CSS STEALTH — oculta controlos antes do DOM existir
//  CAMADA 1  FINGERPRINTER — analisa o DOM e identifica o engine do player
//  CAMADA 2  API HIJACKER — usa a API interna de cada engine para desactivar
//            controlos (não só CSS) e interceptar prototype methods
//  CAMADA 3  DOM SENTINEL — MutationObserver triplo reaplica takeover em
//            qualquer mudança de DOM, attributes ou style
//  CAMADA 4  BRIDGE Flutter↔WebView — postMessage com referência directa ao
//            videoElement real detectado pelo fingerprinter
// ═══════════════════════════════════════════════════════════════════════════════

String get _kCss0Stealth => r"""
  video::-webkit-media-controls,video::-webkit-media-controls-enclosure,
  video::-webkit-media-controls-panel,video::-webkit-media-controls-play-button,
  video::-webkit-media-controls-start-playback-button,
  video::-webkit-media-controls-timeline,video::-webkit-media-controls-current-time-display,
  video::-webkit-media-controls-time-remaining-display,
  video::-webkit-media-controls-mute-button,video::-webkit-media-controls-volume-slider,
  video::-webkit-media-controls-fullscreen-button,
  video::-webkit-media-controls-overflow-button,
  video::-internal-media-controls-download-button,
  video::-webkit-media-controls-overlay-play-button,
  video::-webkit-media-controls-overlay-enclosure {
    display:none!important;visibility:hidden!important;
    opacity:0!important;pointer-events:none!important;
  }
  .vjs-control-bar,.vjs-big-play-button,.vjs-loading-spinner,.vjs-poster,
  .vjs-overlay,.vjs-modal-dialog,.vjs-error-display,.vjs-text-track-display,
  .vjs-playback-rate,.vjs-chapters-button,.vjs-progress-control,
  .video-js .vjs-big-play-button{display:none!important;}
  .jw-controls,.jw-display,.jw-nextup-container,.jw-logo,.jw-dock,
  .jw-captions,.jw-rightclick,.jw-overlays,.jw-controlbar,.jw-icon,
  .jw-button-container{display:none!important;}
  .plyr__controls,.plyr__captions,.plyr__menu,.plyr__progress,.plyr__volume{display:none!important;}
  .ep-logo,.ep-controls,.ep-related,.ep-title,.ep-overlay,
  #eporner-logo,#ep-logo,.eporner-header,.eporner-footer,
  [class*="eporner-nav"],[id*="eporner-ad"]{display:none!important;}
  .pc-overlay,.pc-info-block,.ph-logo,.pc-header,.pc-footer,
  .pc-subscribe-now,.pc-age-gate,.ageGate,.age-gate-wrapper,
  .pcRecoverContent,.removeForEmbed,.pc-overlay-transparent,
  #pc-user-info,.pc-nav,.pc-tabs,.pc-ad,.pc-rating-wrap,
  [class*="pcHeader"],[class*="pc-header"],[id*="pc-header"],
  #player-controls,.player-controls,.playerControlBar,
  .playbackControls,.playerOverlay,[class*="playerControl"],
  [class*="controls-bar"],[id*="controls"]{display:none!important;}
  .redtube-logo,.rt-logo,.site-controls,.embed-logo,
  #redtube_header,.redtube-header,.rt-header,.embed-header,
  .site-branding,.embed-branding,.embed-play-wrap,
  [class*="redtube"],[id*="redtube"]{display:none!important;}
  .xha-header,.xha-logo,.xha-footer,.xha-overlay,
  [class*="xha-"],[class*="ham-header"]{display:none!important;}
  .xv-logo,.xvideos-logo,.xv-header,
  [class*="xvideos-"],[class*="xv-logo"]{display:none!important;}
  .sb-header,.sb-logo,.sb-footer,[class*="spankbang-"]{display:none!important;}
  .redirect-banner,.watch-hd-button,.hd-button,.upgrade-btn,.banner,.ad-banner,
  .popup,.modal,.overlay-redirect,.age-gate,.age-gate-container,
  .age-verification,.agewall,.cookie-consent,.gdpr,.consent-banner,
  [class*="redirect"],[class*="watch-hd"],[class*="upgrade"],
  [class*="notification"],[class*="ageGate"],[class*="age-gate"],
  [class*="age_gate"],[id*="banner"],[id*="ad_"],[id*="ageGate"],
  .site-header,.main-header,#header,.topbar,nav,.navigation,.nav-bar,.navbar,
  .related-videos,.suggestions,.recommendations,
  footer,.footer,.embed-footer{display:none!important;visibility:hidden!important;}
  *,*::before,*::after{box-sizing:border-box!important;}
  html,body{background:#000!important;margin:0!important;padding:0!important;
    overflow:hidden!important;width:100%!important;height:100%!important;}
  video{width:100%!important;height:100%!important;object-fit:contain!important;
    display:block!important;background:#000!important;
    max-width:100vw!important;max-height:100vh!important;}
  iframe{width:100%!important;height:100%!important;border:none!important;}
""";

String get _kJsEngine => r"""
(function(){
'use strict';
if(window.__pxEngine){window.__pxEngine.destroy();}

var ENGINE={
  host:(location.hostname||'').toLowerCase(),
  muted:window.__pxMuted||false,
  videoEl:null,
  apiObj:null,
  engine:'unknown',
  observers:[],
  timers:[],
  commandedPause:false,
  destroyed:false,
};
window.__pxEngine=ENGINE;

function after(ms,fn){
  if(ENGINE.destroyed)return;
  var t=setTimeout(fn,ms);ENGINE.timers.push(t);return t;
}
function observe(target,opts,fn){
  if(!target)return;
  var mo=new MutationObserver(fn);mo.observe(target,opts);ENGINE.observers.push(mo);
}
ENGINE.destroy=function(){
  ENGINE.destroyed=true;
  ENGINE.observers.forEach(function(o){try{o.disconnect();}catch(_){}});
  ENGINE.timers.forEach(function(t){clearTimeout(t);});
  // Restaura prototype.pause se foi interceptado
  if(HTMLMediaElement.__origPausePx){
    HTMLMediaElement.prototype.pause=HTMLMediaElement.__origPausePx;
    delete HTMLMediaElement.__origPausePx;
  }
};

// ── CAMADA 0: CSS ────────────────────────────────────────────────────────────
function applyCss(doc){
  doc=doc||document;
  var id='__pxStealth';
  var el=doc.getElementById(id);
  if(!el){el=doc.createElement('style');el.id=id;(doc.head||doc.documentElement).appendChild(el);}
  el.textContent=window.__pxCss||'';
  if(doc.body){
    doc.body.style.setProperty('background','#000','important');
    doc.body.style.setProperty('overflow','hidden','important');
    doc.body.style.setProperty('margin','0','important');
  }
}
applyCss();

// ── CAMADA 1: FINGERPRINTER ───────────────────────────────────────────────────
// Analisa globals JS + DOM para identificar qual engine de player está activo.
// Devolve fingerprint com: engine, videoEl, containerEl, apiObj, iframeDoc, domInfo.
function fingerprint(){
  var fp={engine:'html5',videoEl:null,containerEl:null,apiObj:null,hasIframe:false,iframeDoc:null,domInfo:{}};

  // Detecta iframes same-origin (RedTube, alguns PH)
  var iframes=document.querySelectorAll('iframe');
  for(var i=0;i<iframes.length;i++){
    try{
      var d=iframes[i].contentDocument||(iframes[i].contentWindow&&iframes[i].contentWindow.document);
      if(d&&d.querySelector('video')){fp.hasIframe=true;fp.iframeDoc=d;break;}
    }catch(_){}
  }

  // VideoJS (usa window.videojs.players registry)
  if(window.videojs&&window.videojs.players){
    var vjsArr=Object.values(window.videojs.players).filter(Boolean);
    if(vjsArr.length>0){
      var vp=vjsArr[0];
      fp.engine='videojs';fp.apiObj=vp;
      try{fp.videoEl=vp.el()?vp.el().querySelector('video'):null;}catch(_){}
      try{fp.containerEl=vp.el();}catch(_){}
      fp.domInfo.vjsVersion=window.videojs.VERSION||'?';
    }
  }

  // JWPlayer (usa window.jwplayer() API)
  if(fp.engine==='html5'&&window.jwplayer){
    try{
      var jw=window.jwplayer();
      if(jw&&typeof jw.getState==='function'){
        fp.engine='jwplayer';fp.apiObj=jw;
        var jwMedia=document.querySelector('.jw-media');
        fp.containerEl=jwMedia||document.getElementById('player');
        fp.videoEl=jwMedia?jwMedia.querySelector('video'):null;
        fp.domInfo.jwState=jw.getState();
      }
    }catch(_){}
  }

  // Plyr (usa .plyr container + window.Plyr)
  if(fp.engine==='html5'&&window.Plyr){
    var plyrEl=document.querySelector('.plyr');
    if(plyrEl){
      fp.engine='plyr';fp.containerEl=plyrEl;
      fp.videoEl=plyrEl.querySelector('video');
      try{fp.apiObj=window.__plyrInstance||null;}catch(_){}
    }
  }

  // Shaka Player (referência em video.__shaka_player__)
  if(fp.engine==='html5'&&window.shaka){
    var shakaV=document.querySelector('video');
    if(shakaV&&shakaV.__shaka_player__){
      fp.engine='shaka';fp.videoEl=shakaV;fp.apiObj=shakaV.__shaka_player__;
    }
  }

  // Flowplayer
  if(fp.engine==='html5'&&window.flowplayer){
    var fpEl=document.querySelector('.fp-player');
    if(fpEl){fp.engine='flowplayer';fp.containerEl=fpEl;fp.videoEl=fpEl.querySelector('video');}
  }

  // Fallback: pega o <video> com maior área visível
  if(!fp.videoEl){
    var all=Array.from(document.querySelectorAll('video'));
    if(fp.iframeDoc)all=all.concat(Array.from(fp.iframeDoc.querySelectorAll('video')));
    all.sort(function(a,b){
      var ra=a.getBoundingClientRect(),rb=b.getBoundingClientRect();
      return(rb.width*rb.height)-(ra.width*ra.height);
    });
    fp.videoEl=all[0]||null;
    if(fp.videoEl)fp.containerEl=fp.videoEl.parentElement;
  }

  fp.domInfo.hasAgeGate=!!(document.querySelector('.age-gate,.ageGate,.age-verification,[id*="age"]'));
  fp.domInfo.totalVideos=document.querySelectorAll('video').length;
  fp.domInfo.totalIframes=iframes.length;

  // Reporta fingerprint para Flutter
  try{
    window.flutter_inappwebview&&window.flutter_inappwebview.callHandler(
      'pxFingerprint',JSON.stringify({engine:fp.engine,hasVideo:!!fp.videoEl,hasIframe:fp.hasIframe,domInfo:fp.domInfo})
    );
  }catch(_){}
  return fp;
}

// ── CAMADA 2: API HIJACKER ────────────────────────────────────────────────────
// Usa a API interna real de cada engine — muito mais robusto do que só CSS.
function hijack(fp){
  if(!fp)return;
  if(fp.videoEl){ENGINE.videoEl=fp.videoEl;ENGINE.engine=fp.engine;ENGINE.apiObj=fp.apiObj;}

  // Takeover genérico de qualquer <video> HTML5
  function takeoverVideo(v){
    if(!v||v.__pxTaken)return;
    v.__pxTaken=true;
    v.removeAttribute('controls');
    v.setAttribute('playsinline','');
    v.setAttribute('webkit-playsinline','');
    v.muted=ENGINE.muted;
    v.style.setProperty('width','100%','important');
    v.style.setProperty('height','100%','important');
    v.style.setProperty('object-fit','contain','important');
    v.style.setProperty('background','#000','important');

    // Bloqueia reposição do atributo "controls" via setAttribute
    var origSet=v.setAttribute.bind(v);
    v.setAttribute=function(name,val){if(name==='controls')return;return origSet(name,val);};

    // Bloqueia controls via getter/setter da propriedade
    try{Object.defineProperty(v,'controls',{get:function(){return false;},set:function(){},configurable:true});}catch(_){}

    // Autoplay com retry exponencial (máx 3 tentativas)
    function tryPlay(n){
      if(ENGINE.destroyed)return;
      var p=v.play();
      if(p&&p.catch)p.catch(function(){if(n<3)after(400*Math.pow(2,n),function(){tryPlay(n+1);});});
    }
    tryPlay(0);

    v.addEventListener('stalled',function(){v.load();tryPlay(0);});
    v.addEventListener('waiting',function(){tryPlay(0);});
    v.addEventListener('suspend',function(){tryPlay(0);});
    v.addEventListener('error',function(){
      var src=v.currentSrc||v.src;
      if(src)after(1000,function(){v.src=src;v.load();tryPlay(0);});
    });

    // Intercepta HTMLMediaElement.prototype.pause para bloquear pausa de terceiros
    if(!HTMLMediaElement.__origPausePx){
      HTMLMediaElement.__origPausePx=HTMLMediaElement.prototype.pause;
      HTMLMediaElement.prototype.pause=function(){
        if(ENGINE.commandedPause){ENGINE.commandedPause=false;return HTMLMediaElement.__origPausePx.call(this);}
        // bloqueia pausa não pedida pelo Flutter
      };
    }
  }

  // VideoJS: usa API para desactivar controlos + intercepta prototype
  function hijackVjs(api){
    if(!api)return;
    try{api.controls(false);}catch(_){}
    try{api.bigPlayButton&&api.bigPlayButton.hide();}catch(_){}
    try{api.controlBar&&api.controlBar.hide();}catch(_){}
    try{api.errorDisplay&&api.errorDisplay.hide();}catch(_){}
    try{api.loadingSpinner&&api.loadingSpinner.hide();}catch(_){}
    try{api.posterImage&&api.posterImage.hide();}catch(_){}
    // Bloqueia reactivação de controlos via prototype
    try{
      var proto=Object.getPrototypeOf(api);
      if(proto&&proto.controls&&!proto.__pxControlsBlocked){
        proto.__pxControlsBlocked=true;
        var orig=proto.controls;
        proto.controls=function(b){if(b===true)return false;return orig.call(this,b);};
      }
    }catch(_){}
    if(fp.videoEl)takeoverVideo(fp.videoEl);
  }

  // JWPlayer: usa setControls(false) + intercepta setup
  function hijackJw(api){
    if(!api)return;
    try{api.setControls(false);}catch(_){}
    try{api.setMute(ENGINE.muted);}catch(_){}
    try{
      var oSetup=api.setup;
      api.setup=function(cfg){cfg=cfg||{};cfg.controls=false;return oSetup.call(this,cfg);};
    }catch(_){}
    if(fp.videoEl)takeoverVideo(fp.videoEl);
  }

  // Plyr: esconde container de controlos via api.elements
  function hijackPlyr(api){
    if(api&&api.elements&&api.elements.controls){
      api.elements.controls.style.setProperty('display','none','important');
    }
    if(fp.videoEl)takeoverVideo(fp.videoEl);
  }

  switch(fp.engine){
    case 'videojs':  hijackVjs(fp.apiObj);  break;
    case 'jwplayer': hijackJw(fp.apiObj);   break;
    case 'plyr':     hijackPlyr(fp.apiObj); break;
    default:         if(fp.videoEl)takeoverVideo(fp.videoEl); break;
  }

  // Takeover em TODOS os <video> do documento
  document.querySelectorAll('video').forEach(takeoverVideo);
  if(fp.iframeDoc){
    applyCss(fp.iframeDoc);
    fp.iframeDoc.querySelectorAll('video').forEach(takeoverVideo);
  }
}

// ── CAMADA 3: DOM SENTINEL ────────────────────────────────────────────────────
var KILL=[
  '.vjs-control-bar','.vjs-big-play-button','.vjs-loading-spinner','.vjs-poster',
  '.vjs-overlay','.vjs-modal-dialog','.vjs-error-display','.vjs-progress-control',
  '.jw-controls','.jw-display','.jw-nextup-container','.jw-logo','.jw-dock',
  '.jw-captions','.jw-rightclick','.jw-overlays','.jw-controlbar',
  '.plyr__controls','.plyr__captions','.plyr__menu','.plyr__progress',
  '.fp-controls','.fp-logo',
  '.ep-logo','.ep-controls','.ep-related','.ep-title','.ep-overlay',
  '#eporner-logo','#ep-logo','.eporner-header','.eporner-footer',
  '.pc-overlay','.pc-info-block','.ph-logo','.pc-header','.pc-footer',
  '.pc-subscribe-now','.ageGate','.age-gate-wrapper','.pcRecoverContent',
  '.removeForEmbed','.pc-overlay-transparent','#pc-user-info',
  '.pc-nav','.pc-tabs','.pc-ad','.pc-rating-wrap',
  '#player-controls','.player-controls','.playerControlBar','.playbackControls',
  '.playerOverlay','[class*="playerControl"]','[class*="controls-bar"]','[id*="controls"]',
  '.redtube-logo','.rt-logo','.site-controls','.embed-logo',
  '#redtube_header','.redtube-header','.rt-header','.embed-header',
  '.site-branding','.embed-branding','.embed-play-wrap',
  '.xha-header','.xha-logo','.xha-footer','.xha-overlay',
  '.xv-logo','.xvideos-logo','.xv-header',
  '.sb-header','.sb-logo','.sb-footer',
  '.redirect-banner','.watch-hd-button','.hd-button','.upgrade-btn',
  '.age-gate','.age-gate-container','.age-verification','.agewall',
  '.cookie-consent','.gdpr','.consent-banner',
  '[id*="banner"]','[id*="ad_"]','[id*="ageGate"]',
  '.site-header','.main-header','#header','.topbar',
  'nav','.navigation','.nav-bar','.navbar',
  '.related-videos','.suggestions','.recommendations',
  'footer','.footer','.embed-footer',
];

function killUnwanted(){
  KILL.forEach(function(s){
    try{document.querySelectorAll(s).forEach(function(el){
      var v=ENGINE.videoEl;
      if(v&&el.contains(v)){el.style.setProperty('background','transparent','important');return;}
      el.remove();
    });}catch(_){}
  });
  document.querySelectorAll('a,span,div,p,button').forEach(function(el){
    var txt=(el.innerText||'').toLowerCase().trim();
    if(!txt||txt.length>120)return;
    if(/redirect|watch.?in.?hd|upgrade|age.?verif|verify.?age/.test(txt)){
      el.style.setProperty('display','none','important');
    }
  });
}

// Observer 1 — nós adicionados/removidos no documento
observe(document.documentElement,{childList:true,subtree:true},function(muts){
  muts.forEach(function(m){
    m.addedNodes.forEach(function(n){
      if(n.nodeType!==1)return;
      if(n.tagName==='VIDEO'){ENGINE.videoEl=n;hijack(fingerprint());return;}
      if(n.tagName==='IFRAME'){after(400,function(){hijack(fingerprint());});}
      if(n.className&&typeof n.className==='string'){
        if(/vjs-|jw-|plyr|overlay|age.gate|redirect|controls|banner/i.test(n.className)){
          try{n.remove();}catch(_){}
        }
      }
    });
  });
  killUnwanted();
});

// Observer 2 — atributos do body (player repõe background/overflow)
observe(document.body||document.documentElement,{attributes:true,attributeFilter:['style','class']},function(){
  if(document.body){
    document.body.style.setProperty('background','#000','important');
    document.body.style.setProperty('overflow','hidden','important');
  }
});

// Observer 3 — atributos nos elementos <video> (reposição de "controls")
function observeVideoEl(v){
  if(!v||v.__pxObserved)return;
  v.__pxObserved=true;
  observe(v,{attributes:true,attributeFilter:['controls','style','class']},function(muts){
    muts.forEach(function(m){
      if(m.attributeName==='controls')v.removeAttribute('controls');
      if(m.attributeName==='style'){
        v.style.setProperty('width','100%','important');
        v.style.setProperty('height','100%','important');
        v.style.setProperty('object-fit','contain','important');
      }
    });
  });
}

// Cookies de age-verification por domínio
(function(){
  var cfg={
    redtube: {d:'.redtube.com',   k:['age_verified=1','platform=pc','accessAgeDisclaimer=1','redtube_session=1']},
    pornhub: {d:'.pornhub.com',   k:['age_verified=1','accessAgeDisclaimerPH=1','accessPH=1','platform=pc','hasVisited=1','cookieConsent=1','_tc=1']},
    xhamster:{d:'.xhamster.com',  k:['age_verified=1','platform=pc','hasVisited=1']},
    youporn: {d:'.youporn.com',   k:['age_verified=1','platform=pc','hasVisited=1']},
    xvideos: {d:'.xvideos.com',   k:['age_verified=1','platform=pc']},
    spankbang:{d:'.spankbang.com',k:['age_verified=1']},
  };
  Object.keys(cfg).forEach(function(key){
    if(ENGINE.host.indexOf(key)<0)return;
    var e='; expires='+new Date(Date.now()+9e11).toUTCString()+'; path=/; domain='+cfg[key].d;
    cfg[key].k.forEach(function(c){document.cookie=c+e;});
  });
})();

// HLS.js para streams adaptativos
function setupHls(v){
  if(!v)return;
  var src=v.currentSrc||v.src||'';
  if(!src){var s=v.querySelector('source[src]');if(s)src=s.src;}
  if(!src)src=v.getAttribute('data-src')||v.getAttribute('data-hls-url')||'';
  if(src.indexOf('.m3u8')<0)return;
  if(typeof Hls==='undefined'||!Hls.isSupported())return;
  if(v.__hls){try{v.__hls.destroy();}catch(_){}}
  var hls=new Hls({maxBufferLength:10,maxMaxBufferLength:20,startLevel:0,autoLevelCapping:2,
    capLevelToPlayerSize:true,lowLatencyMode:false,fragLoadingTimeOut:10000,manifestLoadingTimeOut:10000,
    xhrSetup:function(xhr){xhr.withCredentials=false;}});
  hls.loadSource(src);hls.attachMedia(v);v.__hls=hls;
  hls.on(Hls.Events.MANIFEST_PARSED,function(){var p=v.play();if(p&&p.catch)p.catch(function(){});});
  hls.on(Hls.Events.ERROR,function(ev,data){
    if(data.fatal){
      if(data.type===Hls.ErrorTypes.NETWORK_ERROR)hls.startLoad();
      else if(data.type===Hls.ErrorTypes.MEDIA_ERROR)hls.recoverMediaError();
    }
  });
}
function loadHls(){
  if(typeof Hls!=='undefined'){document.querySelectorAll('video').forEach(setupHls);}
  else{
    var sc=document.createElement('script');
    sc.src='https://cdn.jsdelivr.net/npm/hls.js@1.5.13/dist/hls.min.js';
    sc.onload=function(){document.querySelectorAll('video').forEach(setupHls);};
    (document.head||document.documentElement).appendChild(sc);
  }
}

// ── CAMADA 4: BRIDGE Flutter↔WebView ─────────────────────────────────────────
// Actua no ENGINE.videoEl real (fingerprinter) — não num querySelector genérico
window.addEventListener('message',function(e){
  var v=ENGINE.videoEl||document.querySelector('video');
  if(!v)return;
  if(e.data==='px:play'){var p=v.play();if(p&&p.catch)p.catch(function(){});}
  if(e.data==='px:pause'){
    ENGINE.commandedPause=true;
    if(HTMLMediaElement.__origPausePx)HTMLMediaElement.__origPausePx.call(v);
    else{try{Object.getPrototypeOf(HTMLMediaElement).pause?Object.getPrototypeOf(HTMLMediaElement).pause.call(v):v.pause();}catch(_){v.pause();}}
  }
  if(e.data==='px:mute'){
    ENGINE.muted=true;window.__pxMuted=true;v.muted=true;
    try{ENGINE.apiObj&&ENGINE.apiObj.muted&&ENGINE.apiObj.muted(true);}catch(_){}
    try{ENGINE.apiObj&&ENGINE.apiObj.setMute&&ENGINE.apiObj.setMute(true);}catch(_){}
  }
  if(e.data==='px:unmute'){
    ENGINE.muted=false;window.__pxMuted=false;v.muted=false;
    try{ENGINE.apiObj&&ENGINE.apiObj.muted&&ENGINE.apiObj.muted(false);}catch(_){}
    try{ENGINE.apiObj&&ENGINE.apiObj.setMute&&ENGINE.apiObj.setMute(false);}catch(_){}
  }
  if(e.data==='px:getState'){
    var st={engine:ENGINE.engine,paused:v.paused,muted:v.muted,
      currentTime:v.currentTime,duration:v.duration||0,
      src:v.currentSrc||v.src||'',readyState:v.readyState};
    try{window.flutter_inappwebview&&window.flutter_inappwebview.callHandler('pxState',JSON.stringify(st));}catch(_){}
  }
});

// ── ARRANQUE ──────────────────────────────────────────────────────────────────
function fullRun(){
  if(ENGINE.destroyed)return;
  killUnwanted();
  var fp=fingerprint();
  hijack(fp);
  if(ENGINE.videoEl)observeVideoEl(ENGINE.videoEl);
  document.querySelectorAll('video').forEach(observeVideoEl);
  loadHls();
}

fullRun();
[300,700,1200,2000,3500,6000].forEach(function(ms){after(ms,fullRun);});

})();
""";

// ─────────────────────────────────────────────────────────────────────────────
// Shimmer unificado
// ─────────────────────────────────────────────────────────────────────────────
class _Shimmer extends StatefulWidget {
  final double? width;
  final double? height;
  final double radius;
  const _Shimmer({this.width, this.height, this.radius = 6});
  @override State<_Shimmer> createState() => _ShimmerState();
}
class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..repeat();
    _a = Tween<double>(begin: -2, end: 2).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    builder: (_, __) => Container(
      width: widget.width, height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.radius),
        gradient: LinearGradient(
          begin: Alignment(_a.value - 1, 0), end: Alignment(_a.value + 1, 0),
          colors: AppTheme.current.shimmer,
        ),
      ),
    ),
  );
}

List<Widget> _skeletonCards(int n) => List.generate(n, (_) =>
  Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
    child: Row(children: [
      _Shimmer(width: 160, height: 90, radius: 6),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Shimmer(width: double.infinity, height: 13),
        const SizedBox(height: 5),
        _Shimmer(width: 120, height: 13),
        const SizedBox(height: 5),
        _Shimmer(width: 80, height: 11),
      ])),
    ]),
  ),
);

// ─────────────────────────────────────────────────────────────────────────────
// Player local (estado vazio)
// ─────────────────────────────────────────────────────────────────────────────
class _LocalAssetPlayer extends StatefulWidget {
  final bool muted;
  final bool playing;
  final void Function(VideoPlayerController) onReady;
  const _LocalAssetPlayer({required this.muted, required this.playing, required this.onReady});
  @override State<_LocalAssetPlayer> createState() => _LocalAssetPlayerState();
}
class _LocalAssetPlayerState extends State<_LocalAssetPlayer> {
  late VideoPlayerController _ctrl;
  bool _initialized = false;
  @override void initState() {
    super.initState();
    _ctrl = VideoPlayerController.asset('assets/videos/promo.mp4')
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _initialized = true);
        _ctrl.setLooping(true);
        _ctrl.setVolume(widget.muted ? 0.0 : 1.0);
        if (widget.playing) _ctrl.play();
        widget.onReady(_ctrl);
      });
  }
  @override void didUpdateWidget(_LocalAssetPlayer old) {
    super.didUpdateWidget(old);
    if (old.muted != widget.muted) _ctrl.setVolume(widget.muted ? 0.0 : 1.0);
    if (old.playing != widget.playing && _initialized) {
      widget.playing ? _ctrl.play() : _ctrl.pause();
    }
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    if (!_initialized) return const ColoredBox(color: Colors.black);
    return FittedBox(fit: BoxFit.cover,
      child: SizedBox(width: _ctrl.value.size.width, height: _ctrl.value.size.height,
        child: VideoPlayer(_ctrl)));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Play/Pause overlay — auto-hide, não bloqueia WebView
// ─────────────────────────────────────────────────────────────────────────────
class _PlayPauseOverlay extends StatefulWidget {
  final bool playing;
  final VoidCallback onTap;
  const _PlayPauseOverlay({required this.playing, required this.onTap});
  @override State<_PlayPauseOverlay> createState() => _PlayPauseOverlayState();
}
class _PlayPauseOverlayState extends State<_PlayPauseOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _opacity;
  Timer? _hideTimer;

  @override void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _opacity = CurvedAnimation(parent: _ac, curve: Curves.easeOut);
    _showTemporarily();
  }

  void _showTemporarily() {
    _hideTimer?.cancel();
    _ac.forward();
    if (widget.playing) {
      _hideTimer = Timer(const Duration(milliseconds: 2500), () {
        if (mounted) _ac.reverse();
      });
    }
  }

  void _handleTap() { widget.onTap(); _showTemporarily(); }

  @override void didUpdateWidget(_PlayPauseOverlay old) {
    super.didUpdateWidget(old);
    if (!widget.playing && old.playing) { _hideTimer?.cancel(); _ac.forward(); }
    if (widget.playing && !old.playing) _showTemporarily();
  }

  @override void dispose() { _hideTimer?.cancel(); _ac.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.translucent,
    onTap: _handleTap,
    child: FadeTransition(
      opacity: _opacity,
      child: Center(
        child: Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.72),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, spreadRadius: 4)],
          ),
          child: Center(child: SvgPicture.string(
            widget.playing ? _svgPause : _svgPlay, width: 28, height: 28,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn))),
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// ExibicaoPage
// ─────────────────────────────────────────────────────────────────────────────
class ExibicaoPage extends StatefulWidget {
  final String? embedUrl;
  final FeedVideo? currentVideo;
  final void Function(FeedVideo) onVideoTap;
  final bool isActive;
  const ExibicaoPage({super.key, this.embedUrl, this.currentVideo,
      required this.onVideoTap, this.isActive = true});
  @override State<ExibicaoPage> createState() => _ExibicaoPageState();
}

class _ExibicaoPageState extends State<ExibicaoPage>
    with AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive => true;

  final List<FeedVideo> _related = [];
  bool   _loadingRelated = false;
  InAppWebViewController? _webCtrl;
  VideoPlayerController? _localCtrl;
  bool   _muted          = false;
  bool   _playing        = true;
  bool   _playerLoading  = true;
  FeedVideo? _nextVideo;
  String _detectedEngine = '—';

  bool get _isEmpty => widget.embedUrl == null || widget.currentVideo == null;

  @override void initState() {
    super.initState();
    if (!_isEmpty) { _loadRelated(); _startPlayerTimeout(); }
  }

  void _startPlayerTimeout() {
    Future.delayed(const Duration(seconds: 12), () {
      if (mounted && _playerLoading) setState(() => _playerLoading = false);
    });
  }

  @override void didUpdateWidget(ExibicaoPage old) {
    super.didUpdateWidget(old);
    if (widget.currentVideo != old.currentVideo && !_isEmpty) {
      setState(() { _playerLoading = true; _playing = true; _detectedEngine = '—'; });
      _loadRelated();
      _startPlayerTimeout();
    }
    if (widget.isActive != old.isActive) {
      _webSend(widget.isActive ? 'px:play' : 'px:pause');
      setState(() => _playing = widget.isActive);
    }
  }

  void _webSend(String msg) =>
      _webCtrl?.evaluateJavascript(source: "window.postMessage('$msg','*')");

  Future<void> _loadRelated() async {
    if (!mounted) return;
    setState(() { _loadingRelated = true; _related.clear(); });
    final videos = await FeedFetcher.fetchAll(Random().nextInt(30) + 1);
    if (!mounted) return;
    setState(() {
      _related..clear()..addAll(videos.where((v) => v.embedUrl != widget.embedUrl).take(20));
      _loadingRelated = false;
    });
  }

  void _snack(String msg) {
    final t = AppTheme.current;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: TextStyle(color: t.toastText)),
      backgroundColor: t.toastBg, behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2)));
  }

  Future<void> _forceDownload() async {
    if (_webCtrl == null) return;
    final video = widget.currentVideo; if (video == null) return;
    _snack('A capturar link do vídeo...');
    try {
      // Usa ENGINE.videoEl real detectado pelo fingerprinter
      final result = await _webCtrl!.evaluateJavascript(source: r'''
        (function(){
          var E=window.__pxEngine;
          var v=(E&&E.videoEl)||document.querySelector('video');
          if(!v)return '__none__';
          var s=v.currentSrc||v.src||'';
          if(s&&s.startsWith('http'))return s;
          var src=document.querySelector('source[src]');
          return src&&src.src&&src.src.startsWith('http')?src.src:'__none__';
        })()''');
      final src = result?.toString().replaceAll('"', '').trim() ?? '__none__';
      if (!mounted) return;
      if (src == '__none__' || src.isEmpty) { _snack('Inicia a reprodução antes.'); return; }
      DownloadService.instance.startDownload(url: src, title: video.title,
          type: 'video', thumbUrl: video.thumb, sourceUrl: video.embedUrl);
      _snack('Download iniciado');
    } catch (_) { if (mounted) _snack('Erro ao capturar o vídeo.'); }
  }

  void _togglePlay() {
    final np = !_playing;
    setState(() => _playing = np);
    if (_isEmpty) { np ? _localCtrl?.play() : _localCtrl?.pause(); }
    else { _webSend(np ? 'px:play' : 'px:pause'); }
  }

  void _toggleMute() {
    final nm = !_muted;
    setState(() => _muted = nm);
    if (_isEmpty) { _localCtrl?.setVolume(nm ? 0.0 : 1.0); }
    else { _webSend(nm ? 'px:mute' : 'px:unmute'); }
  }

  Future<void> _openAdsUrl() async {
    final uri = Uri.parse(_kAdsUrl);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // FASE A: CSS stealth (onLoadStart) — zero JS pesado, só estilo imediato
  Future<void> _injectPhaseA(InAppWebViewController ctrl) async {
    try {
      await ctrl.evaluateJavascript(source:
          "if(window.__pxEngine){window.__pxEngine.destroy();window.__pxEngine=null;}");
      final esc = _kCss0Stealth
          .replaceAll('\\', '\\\\').replaceAll("'", "\\'")
          .replaceAll('\n', '\\n').replaceAll('\r', '');
      await ctrl.evaluateJavascript(source:
          "window.__pxCss='$esc';window.__pxMuted=$_muted;");
      await ctrl.evaluateJavascript(source:
          "(function(){var s=document.getElementById('__pxStealth');"
          "if(!s){s=document.createElement('style');s.id='__pxStealth';"
          "(document.head||document.documentElement).appendChild(s);}"
          "s.textContent=window.__pxCss||'';"
          "if(document.body){document.body.style.background='#000';"
          "document.body.style.overflow='hidden';}})()");
    } catch (_) {}
  }

  // FASE B: motor completo (onLoadStop) — fingerprinter + hijacker + sentinels
  Future<void> _injectPhaseB(InAppWebViewController ctrl) async {
    try {
      await _injectPhaseA(ctrl);
      await ctrl.evaluateJavascript(source: _kJsEngine);
      if (_playing) {
        await Future.delayed(const Duration(milliseconds: 900));
        if (mounted) _webSend('px:play');
      }
    } catch (_) {}
  }

  void _showVideoMenu(BuildContext ctx, FeedVideo v, Offset pos) {
    final t = AppTheme.current;
    final RenderBox overlay = Overlay.of(ctx).context.findRenderObject() as RenderBox;
    showMenu<String>(
      context: ctx, color: t.popup, elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: t.borderSoft)),
      position: RelativeRect.fromRect(pos & const Size(1,1), Offset.zero & overlay.size),
      items: [
        _popItem('save',     _svgSaveLater, 'Guardar para assistir mais tarde', t),
        _popItem('playlist', _svgPlaylist,  'Adicionar na minha playlist',      t),
        _popItem('next',     _svgPlayNext,  'Exibir como próximo vídeo',        t),
      ],
    ).then((val) {
      if (val == null || !mounted) return;
      switch (val) {
        case 'save':     _snack('Guardado para assistir mais tarde'); break;
        case 'playlist': _snack('Adicionado à playlist'); break;
        case 'next':     setState(() => _nextVideo = v); _snack('Será exibido a seguir'); break;
      }
    });
  }

  PopupMenuItem<String> _popItem(String val, String svg, String label, AppTheme t) =>
    PopupMenuItem<String>(value: val, height: 46,
      child: Row(children: [
        SvgPicture.string(svg, width: 18, height: 18,
            colorFilter: ColorFilter.mode(t.iconSub, BlendMode.srcIn)),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: TextStyle(color: t.text, fontSize: 13.5))),
      ]));

  @override Widget build(BuildContext context) {
    super.build(context);
    final t = AppTheme.current;
    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: t.isDark ? Brightness.light : Brightness.dark,
    );
    final screenW = MediaQuery.of(context).size.width;
    final playerH = screenW * 9 / 16;
    final video   = widget.currentVideo;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: t.bg,
        body: SafeArea(
          bottom: false,
          child: Column(children: [

            // ── Player ────────────────────────────────────────────────────────
            SizedBox(width: screenW, height: playerH,
              child: ColoredBox(color: Colors.black,
                child: Stack(children: [

                  Positioned.fill(
                    child: _isEmpty
                        ? _LocalAssetPlayer(
                            muted: _muted, playing: _playing,
                            onReady: (ctrl) { if (mounted) setState(() => _localCtrl = ctrl); })
                        : InAppWebView(
                            key: ValueKey(widget.embedUrl),
                            initialUrlRequest: URLRequest(url: WebUri(widget.embedUrl!)),
                            initialSettings: InAppWebViewSettings(
                              javaScriptEnabled: true,
                              mediaPlaybackRequiresUserGesture: false,
                              allowsInlineMediaPlayback: true,
                              transparentBackground: true,
                              disableDefaultErrorPage: true,
                              disableHorizontalScroll: true,
                              disableVerticalScroll: false,
                              supportZoom: false,
                              builtInZoomControls: false,
                              displayZoomControls: false,
                              horizontalScrollBarEnabled: false,
                              verticalScrollBarEnabled: false,
                              mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                              allowFileAccessFromFileURLs: true,
                              allowUniversalAccessFromFileURLs: true,
                              safeBrowsingEnabled: false,
                              thirdPartyCookiesEnabled: true,
                              domStorageEnabled: true,
                              databaseEnabled: true,
                              useOnLoadResource: true,
                              useShouldInterceptRequest: false,
                              userAgent: 'Mozilla/5.0 (Linux; Android 13; Pixel 7) '
                                  'AppleWebKit/537.36 (KHTML, like Gecko) '
                                  'Chrome/124.0.0.0 Mobile Safari/537.36',
                            ),
                            onWebViewCreated: (ctrl) {
                              _webCtrl = ctrl;
                              // Canal: fingerprint reportado pelo motor JS
                              ctrl.addJavaScriptHandler(
                                handlerName: 'pxFingerprint',
                                callback: (args) {
                                  if (!mounted || args.isEmpty) return;
                                  try {
                                    final data = args[0] is String
                                        ? Map<String,dynamic>.from({})
                                        : args[0] as Map<String,dynamic>;
                                    // args[0] pode vir como String JSON
                                    String eng = '?';
                                    if (args[0] is String) {
                                      eng = RegExp(r'"engine":"([^"]+)"')
                                          .firstMatch(args[0] as String)?.group(1) ?? '?';
                                    } else {
                                      eng = (args[0] as Map)['engine']?.toString() ?? '?';
                                    }
                                    setState(() => _detectedEngine = eng);
                                  } catch (_) {}
                                },
                              );
                              // Canal: estado do player reportado pelo motor
                              ctrl.addJavaScriptHandler(
                                handlerName: 'pxState',
                                callback: (args) {
                                  if (!mounted || args.isEmpty) return;
                                  try {
                                    final raw = args[0];
                                    bool paused = false;
                                    if (raw is String) {
                                      paused = raw.contains('"paused":true');
                                    } else if (raw is Map) {
                                      paused = raw['paused'] == true;
                                    }
                                    if (mounted && _playing == paused) {
                                      setState(() => _playing = !paused);
                                    }
                                  } catch (_) {}
                                },
                              );
                            },
                            onLoadStart: (ctrl, url) async { await _injectPhaseA(ctrl); },
                            onLoadStop: (ctrl, _) async {
                              await _injectPhaseB(ctrl);
                              if (mounted) setState(() => _playerLoading = false);
                            },
                            onLoadError: (ctrl, url, code, msg) async {
                              await _injectPhaseB(ctrl);
                              if (mounted) setState(() => _playerLoading = false);
                            },
                            shouldOverrideUrlLoading: (ctrl, action) async {
                              final url = action.request.url?.toString() ?? '';
                              final navType = action.navigationType;
                              if (navType == NavigationType.LINK_ACTIVATED ||
                                  navType == NavigationType.FORM_SUBMITTED) {
                                final embedDomains = ['eporner.com','pornhub.com','redtube.com',
                                  'embed.redtube.com','youporn.com','xvideos.com','xhamster.com',
                                  'spankbang.com','bravotube.net','drtuber.com','txxx.com',
                                  'gotporn.com','porndig.com','xnxx.com','xvideos2.com'];
                                if (!embedDomains.any((d)=>url.contains(d)) && url.startsWith('http')) {
                                  return NavigationActionPolicy.CANCEL;
                                }
                              }
                              return NavigationActionPolicy.ALLOW;
                            },
                          ),
                  ),

                  // Thumbnail de loading
                  if (!_isEmpty && _playerLoading)
                    Positioned.fill(child: Stack(children: [
                      if (video?.thumb != null && video!.thumb.isNotEmpty)
                        Image.network(video.thumb, fit: BoxFit.cover,
                          width: double.infinity, height: double.infinity,
                          headers: const {'User-Agent': 'Mozilla/5.0'},
                          errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black)),
                      Container(color: Colors.black54),
                      const Center(child: CircularProgressIndicator(color: Colors.white70, strokeWidth: 1.5)),
                    ])),

                  // Play/Pause overlay (auto-hide, não bloqueia WebView)
                  Positioned.fill(child: _PlayPauseOverlay(playing: _playing, onTap: _togglePlay)),

                  // Gradiente inferior para legibilidade dos botões
                  Positioned(left:0,right:0,bottom:0,
                    child: Container(height: 72,
                      decoration: const BoxDecoration(gradient: LinearGradient(
                        begin: Alignment.bottomCenter, end: Alignment.topCenter,
                        colors: [Color(0xCC000000), Colors.transparent])))),

                  // Badge engine detectado (canto sup esq)
                  if (!_isEmpty && _detectedEngine != '—')
                    Positioned(top:6, left:8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(4)),
                        child: Text('⚙ $_detectedEngine',
                          style: const TextStyle(color: Colors.white70,
                              fontSize: 9, fontWeight: FontWeight.w600)))),

                  // Botões bottom-right
                  Positioned(bottom:8, right:8,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      _PlayerBtn(svg: _muted ? _svgVolOff : _svgVolOn, onTap: _toggleMute),
                      const SizedBox(height: 8),
                      _PlayerBtn(svg: _svgDl, onTap: _forceDownload),
                    ])),
                ]),
              ),
            ),

            // ── Corpo ─────────────────────────────────────────────────────────
            Expanded(
              child: _isEmpty
                  ? _EmptyBody(onAdsLinkTap: _openAdsUrl)
                  : ListView(
                      padding: EdgeInsets.zero,
                      physics: const ClampingScrollPhysics(),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                            Text(video!.title, style: TextStyle(color: t.text, fontSize: 14.5,
                                fontWeight: FontWeight.w600, height: 1.3)),
                            const SizedBox(height: 6),

                            Row(children: [
                              ClipRRect(borderRadius: BorderRadius.circular(6),
                                child: Image.network(faviconForSource(video.source),
                                    width: 14, height: 14,
                                    errorBuilder: (_, __, ___) => const SizedBox(width: 14, height: 14))),
                              const SizedBox(width: 5),
                              Text(video.sourceLabel, style: TextStyle(
                                  color: t.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w500)),
                              if (video.views.isNotEmpty)
                                Text('  ·  ${video.views} vis.',
                                    style: TextStyle(color: t.textHint, fontSize: 11.5)),
                              if (_detectedEngine != '—') ...[
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppTheme.ytRed.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(4)),
                                  child: Text(_detectedEngine, style: TextStyle(
                                      color: AppTheme.ytRed, fontSize: 10, fontWeight: FontWeight.w700))),
                              ],
                            ]),

                            const SizedBox(height: 12),
                            Divider(color: t.divider, thickness: 1, height: 1),
                            const SizedBox(height: 10),

                            if (_nextVideo != null) ...[
                              GestureDetector(
                                onTap: () { widget.onVideoTap(_nextVideo!); setState(() => _nextVideo = null); },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: t.isDark ? const Color(0xFF2A1A1A) : const Color(0xFFFFF0F0),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: t.isDark ? const Color(0xFF5A2020) : const Color(0xFFFFCCCC))),
                                  child: Row(children: [
                                    SvgPicture.string(_svgPlaylist, width: 15, height: 15,
                                        colorFilter: ColorFilter.mode(AppTheme.ytRed, BlendMode.srcIn)),
                                    const SizedBox(width: 10),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text('Seguinte:', style: TextStyle(color: AppTheme.ytRed,
                                          fontSize: 11, fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 2),
                                      Text(_nextVideo!.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: t.text, fontSize: 12.5, fontWeight: FontWeight.w600)),
                                      Text(_nextVideo!.sourceLabel,
                                          style: TextStyle(color: t.textSecondary, fontSize: 11)),
                                    ])),
                                    GestureDetector(
                                      onTap: () => setState(() => _nextVideo = null),
                                      child: Padding(padding: const EdgeInsets.only(left: 8),
                                          child: Icon(Icons.close_rounded, color: t.iconTertiary, size: 18))),
                                  ]),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],

                            Text('Relacionados', style: TextStyle(color: t.text,
                                fontSize: 13.5, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                          ]),
                        ),

                        if (_loadingRelated)
                          Column(children: _skeletonCards(5))
                        else
                          ..._related.map((v) => _RelatedCard(
                              video: v,
                              onTap: () {
                                if (_nextVideo?.embedUrl == v.embedUrl) setState(() => _nextVideo = null);
                                widget.onVideoTap(v);
                              },
                              onMenuTap: (pos) => _showVideoMenu(context, v, pos))),

                        const SizedBox(height: 24),
                      ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── Botão flutuante do player ────────────────────────────────────────────────
class _PlayerBtn extends StatelessWidget {
  final String svg;
  final VoidCallback onTap;
  const _PlayerBtn({required this.svg, required this.onTap});
  @override Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7), shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8)]),
      child: Center(child: SvgPicture.string(svg, width: 18, height: 18,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)))));
}

// ─── Estado vazio ─────────────────────────────────────────────────────────────
class _EmptyBody extends StatelessWidget {
  final VoidCallback onAdsLinkTap;
  const _EmptyBody({required this.onAdsLinkTap});
  @override Widget build(BuildContext context) {
    final t = AppTheme.current;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(color: t.surface, padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Bem-vindo ao nuxx', style: TextStyle(color: t.text, fontSize: 18,
              fontWeight: FontWeight.w700, height: 1.2)),
          const SizedBox(height: 6),
          Text('Selecione qualquer vídeo na aba feed para ser exibido aqui...',
              style: TextStyle(color: t.textSecondary, fontSize: 13.5, height: 1.4)),
          const SizedBox(height: 8),
          GestureDetector(onTap: onAdsLinkTap,
            child: Text('Publicitar minha marca', style: TextStyle(
                color: t.emptyLinkText, fontSize: 13.5, fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline, decorationColor: t.emptyLinkText))),
        ])),
      Expanded(child: Center(child: SizedBox(width: 200, height: 200,
        child: Lottie.asset('assets/lottie/Cat_playing_animation.json',
          repeat: true, animate: true,
          errorBuilder: (_, __, ___) => SvgPicture.string(svgExibicaoOutline,
              width: 72, height: 72,
              colorFilter: ColorFilter.mode(t.emptyIcon, BlendMode.srcIn)))))),
    ]);
  }
}

// ─── Card relacionado — horizontal compacto ───────────────────────────────────
class _RelatedCard extends StatelessWidget {
  final FeedVideo video;
  final VoidCallback onTap;
  final void Function(Offset) onMenuTap;
  const _RelatedCard({required this.video, required this.onTap, required this.onMenuTap});

  static Map<String, String> _headers(VideoSource src) {
    const ua = 'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36';
    final origins = {
      VideoSource.eporner:'https://www.eporner.com/', VideoSource.pornhub:'https://www.pornhub.com/',
      VideoSource.redtube:'https://www.redtube.com/', VideoSource.youporn:'https://www.youporn.com/',
      VideoSource.xvideos:'https://www.xvideos.com/', VideoSource.xhamster:'https://xhamster.com/',
      VideoSource.spankbang:'https://spankbang.com/', VideoSource.bravotube:'https://www.bravotube.net/',
      VideoSource.drtuber:'https://www.drtuber.com/', VideoSource.txxx:'https://www.txxx.com/',
      VideoSource.gotporn:'https://www.gotporn.com/', VideoSource.porndig:'https://www.porndig.com/',
    };
    return {'User-Agent':ua,'Accept':'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
        'Accept-Language':'pt-PT,pt;q=0.9,en;q=0.8',
        if(origins[src]!=null)'Referer':origins[src]!};
  }

  @override Widget build(BuildContext context) {
    final t = AppTheme.current;
    return GestureDetector(
      onTap: onTap, behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 8, 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 160, height: 90,
            child: Stack(fit: StackFit.expand, children: [
              ClipRRect(borderRadius: BorderRadius.circular(6),
                child: _ThumbCompact(url: video.thumb, headers: _headers(video.source), bg: t.thumbBg)),
              if (video.duration.isNotEmpty)
                Positioned(bottom:4, right:5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal:4, vertical:1),
                    decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(3)),
                    child: Text(video.duration, style: const TextStyle(
                        color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)))),
            ])),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(video.title, style: TextStyle(color: t.text, fontSize: 13,
                fontWeight: FontWeight.w500, height: 1.3),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text('${video.sourceLabel}${video.views.isNotEmpty?"  ·  ${video.views} vis.":""}',
                style: TextStyle(color: t.textSecondary, fontSize: 11.5)),
          ])),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => onMenuTap(d.globalPosition),
            child: Padding(padding: const EdgeInsets.symmetric(horizontal:4, vertical:4),
                child: Icon(Icons.more_vert_rounded, color: t.iconTertiary, size: 20))),
        ])));
  }
}

class _ThumbCompact extends StatefulWidget {
  final String url;
  final Map<String, String> headers;
  final Color bg;
  const _ThumbCompact({required this.url, required this.headers, required this.bg});
  @override State<_ThumbCompact> createState() => _ThumbCompactState();
}
class _ThumbCompactState extends State<_ThumbCompact> {
  int _attempt = 0; bool _failed = false;
  @override Widget build(BuildContext context) {
    final t = AppTheme.current;
    if (widget.url.isEmpty || _failed)
      return Container(color: widget.bg,
          child: Center(child: Icon(Icons.play_circle_outline_rounded, color: t.iconSub, size: 32)));
    return Image.network(
      _attempt == 0 ? widget.url : '${widget.url}?_r=$_attempt',
      key: ValueKey('${widget.url}_$_attempt'),
      fit: BoxFit.cover, headers: widget.headers,
      errorBuilder: (_, __, ___) {
        if (_attempt < 1) WidgetsBinding.instance.addPostFrameCallback((_){if(mounted)setState(()=>_attempt++);});
        else WidgetsBinding.instance.addPostFrameCallback((_){if(mounted)setState(()=>_failed=true);});
        return Container(color: widget.bg,
            child: Center(child: Icon(Icons.play_circle_outline_rounded, color: t.iconSub, size: 32)));
      },
      loadingBuilder: (_, child, p) => p == null ? child : _Shimmer(radius: 0),
    );
  }
}
