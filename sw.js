const CACHE='helpmeid-app-shell-v1';
const HOME=new URL('./index.html',self.location.href).href;
const ASSETS=['./index.html','./manifest.webmanifest','./icon.svg'].map(p=>new URL(p,self.location.href).href);
self.addEventListener('install',e=>{e.waitUntil((async()=>{const c=await caches.open(CACHE);await c.addAll(ASSETS.map(u=>new Request(u,{cache:'reload'})));await self.skipWaiting()})())});
self.addEventListener('activate',e=>{e.waitUntil((async()=>{for(const key of await caches.keys())if(key.startsWith('helpmeid-app-shell-')&&key!==CACHE)await caches.delete(key);await self.clients.claim()})())});
self.addEventListener('fetch',e=>{
 const req=e.request,url=new URL(req.url);
 if(req.method!=='GET'||url.origin!==self.location.origin||!url.pathname.startsWith(new URL('./',self.location.href).pathname))return;
 // Explicit update checks must reach the published site, never a cached copy.
 if(url.searchParams.has('update')&&req.mode!=='navigate')return;
 if(req.mode==='navigate'){
  e.respondWith((async()=>{const c=await caches.open(CACHE);try{const r=await fetch(req,{cache:'no-store'});if(r.ok)await c.put(HOME,r.clone());return r}catch(err){return await c.match(HOME)||Response.error()}})());
 }else if(ASSETS.includes(url.href)){
  e.respondWith((async()=>{const c=await caches.open(CACHE);try{const r=await fetch(req,{cache:'no-store'});if(r.ok)await c.put(url.href,r.clone());return r}catch(err){return await c.match(url.href)||Response.error()}})());
 }
});
