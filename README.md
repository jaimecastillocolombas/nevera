# Casa NFC

Lista de la compra y tareas de casa, pensada para abrirse acercando el móvil a
una pegatina NFC. Sin instalar nada: es una web (PWA) que se puede añadir a la
pantalla de inicio.

- **Pegatina de la nevera** → `?z=nevera` → lista de la compra
- **Pegatina del pasillo / cocina** → `?z=tareas` → tareas, puntos y recompensas

Cada persona elige su nombre la primera vez que abre la app en su móvil, y a
partir de ahí todo lo que añade o completa queda con su nombre.

---

## Qué hay aquí

```
index.html            la app entera (HTML + CSS + JS en un solo archivo)
manifest.webmanifest  para que se pueda instalar en la pantalla de inicio
sw.js                 service worker: funciona sin cobertura en el súper
supabase.sql          esquema de la base de datos
icons/                iconos de la app
```

---

## 1. Probarlo ya, sin backend

Abre `index.html` con cualquier servidor estático:

```bash
npx serve .
```

Funciona en **modo local**: los datos se guardan en el navegador de ese móvil.
Sirve para ver cómo va, pero cada móvil tendrá su propia lista.

## 2. Conectar la base de datos (para que la casa comparta lista)

1. Crea un proyecto gratis en [supabase.com](https://supabase.com).
2. **SQL Editor → New query**, pega todo `supabase.sql` y dale a *Run*.
3. **Project Settings → API**: copia *Project URL* y la clave *anon public*.
4. Ábrelas en `index.html`, arriba del todo del `<script>`:

```js
const SUPABASE_URL      = "https://xxxxxxxx.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGci...";
```

Eso es todo. Los cambios llegan solos a los demás móviles (Realtime), sin
recargar.

> La clave `anon` es pública por diseño y las políticas están abiertas a
> cualquiera que tenga la URL de la app. Es un tablón de casa: no metas ahí
> nada que no quieras que vea alguien con el enlace.

## 3. Desplegar

Netlify, Vercel o GitHub Pages sirven igual, es todo estático.

```bash
# Netlify
npx netlify-cli deploy --prod --dir .
```

Apunta el dominio que te dé (o uno propio) y ya tienes la URL para las
pegatinas.

## 4. Grabar las pegatinas NFC

Etiquetas **NTAG216** (888 bytes útiles; una URL como la nuestra ocupa ~40, así
que sobra sitio de largo). Con la app **NFC Tools** (Android o iPhone):

1. *Escribir* → *Añadir un registro* → **URL**
2. Nevera: `https://TU-DOMINIO/?z=nevera`
3. Otra zona: `https://TU-DOMINIO/?z=tareas`
4. *Escribir* y acercar la etiqueta. Bloquéala si no quieres que se
   reescriba por error.

Notas:

- **iPhone** (XS o posterior): lee etiquetas sin abrir nada, sale una
  notificación arriba. No hace falta app.
- **Android**: hay que tener el NFC activado en ajustes.
- No pegues la etiqueta directamente sobre metal — la puerta de la nevera lo
  es. Usa una etiqueta *on-metal*, o pon un trozo de cartón/fieltro debajo, o
  pégala en un imán de plástico.

## 5. Modo padres

Ajustes → *Modo padres* → PIN **1234** (cámbialo ahí mismo).

Con el modo padres activo se pueden crear y borrar tareas y recompensas, y
aprobar o rechazar los canjes de puntos. Los puntos se descuentan al pedir el
canje y vuelven si se rechaza.

---

## Cómo funciona por dentro

- **Una sola capa de datos** (`State.store`) con dos implementaciones,
  `LocalStore` y `SupaStore`, con la misma API (`load`, `insert`, `update`,
  `remove`, `onChange`). Cambiar de una a otra es sólo rellenar las dos
  constantes.
- **Puntos calculados, no guardados**: el saldo de cada uno sale de
  `logs` menos `redemptions`, así dos móviles escribiendo a la vez no pueden
  descuadrar el marcador.
- **Categorías automáticas**: `guessCat()` clasifica "tomates" en *Fresco* y
  "fairy" en *Limpieza* con un diccionario de palabras. Amplíalo en
  `KEYWORDS`.
- **Cantidades**: `parseEntry()` entiende "6 huevos", "2kg patatas" y
  "leche x2" y separa la cantidad del producto.
- **Modo súper**: agranda los toques, esconde quién añadió qué y quita las
  cabeceras de categoría, para ir tachando con el carro en la mano.

## Ideas para después

- Productos recurrentes: "esto lo compramos cada semana" → se repone solo.
- Historial de precios y gasto por compra.
- Notificación push cuando alguien añade algo a la lista.
- Racha semanal de tareas (bonus por completar X días seguidos).
- Un tercer NFC en la entrada con recados y avisos.
