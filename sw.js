const CACHE='helpmeid-app-shell-v1';
const HOME=new URL('./index.html',self.location.href).href;
const ASSETS=['./manifest.webmanifest','./icon.svg'].map(p=>new URL(p,self.location.href).href);
self.addEventListener('install',e=>{e.waitUntil((async()=>{const c=await caches.open(CACHE);await Promise.allSettled(ASSETS.map(async u=>{const r=await fetch(u,{cache:'reload'});if(r.ok)await c.put(u,r)}));if(!await c.match(HOME)){const r=await fetch(HOME,{cache:'reload'});if(r.ok)await c.put(HOME,r)}await self.skipWaiting()})())});
self.addEventListener('activate',e=>{e.waitUntil(self.clients.claim())});
self.addEventListener('fetch',e=>{
 const req=e.request,url=new URL(req.url),scope=new URL('./',self.location.href).pathname;
 if(req.method!=='GET'||url.origin!==self.location.origin||!url.pathname.startsWith(scope))return;
 if(url.searchParams.has('update')&&req.mode!=='navigate')return;
 if(req.mode==='navigate'&&(url.pathname===scope||url.pathname===new URL(HOME).pathname)){
  e.respondWith((async()=>{const c=await caches.open(CACHE);
   // Keep the installed version until the user accepts an update.
   if(!url.searchParams.has('update')){const old=await c.match(HOME);if(old)return old}
   try{const r=await fetch(req,{cache:'no-store'});if(r.ok)await c.put(HOME,r.clone());return r}catch(err){return await c.match(HOME)||Response.error()}
  })());
 }else if(ASSETS.includes(url.href)){
  e.respondWith((async()=>{const c=await caches.open(CACHE);const old=await c.match(url.href);if(old)return old;const r=await fetch(req);if(r.ok)await c.put(url.href,r.clone());return r})());
 }
});
