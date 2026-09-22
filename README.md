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

## 5. Personas y perfil de padres

Cada persona tiene su propio PIN. La primera vez que alguien elige su nombre
en un móvil, la app le pide crearlo por duplicado (escribirlo y repetirlo); a
partir de ahí ese móvil recuerda quién es y no vuelve a preguntar.

No hay ningún "modo padres" que activar: los permisos van pegados a la
persona. Si entras como alguien con `is_parent = true`, ya los tienes.
Añadir gente a la casa también es cosa de padres, desde sus ajustes.

Quien esté marcado como **padre o madre** (`members.is_parent`) ve, además:

- **+ Nueva** en Tareas y Recompensas, y un ✎ para editarlas o borrarlas.
- **Ajustar puntos**: sumar o restar puntos a mano con un motivo, que queda
  escrito en el historial. También se llega tocando la tarjeta de alguien en
  el marcador.
- **Aprobar o rechazar canjes.** Los puntos se descuentan al pedir el canje y
  vuelven si se rechaza.
- **Historial con ↩**: deshacer cualquier tarea o canje mal apuntado.
- **Personas de la casa** en Ajustes: añadir gente, cambiar quién es padre y
  resetear el PIN de alguien que lo haya olvidado (escribiendo `quitar` en el
  campo del PIN, para que elija uno nuevo al entrar).

Si alguien olvida su PIN y no hay ningún padre a mano, se borra desde
Supabase: tabla `members`, columna `pin` a `null`.

## 6. Rechazos y avisos

Un padre o madre puede **rechazar** dos cosas, siempre escribiendo un motivo:

- Una **tarea** ya marcada como hecha, desde el ✕ de su línea en el historial.
- Un **canje** pendiente, desde el ✕ de la sección *Canjes pendientes*.

Una tarea rechazada **no se borra**: se queda en el historial tachada, con
quién la rechazó y por qué, y pasa a valer 0 puntos. El ↩ la restaura y
devuelve los puntos. Un canje rechazado devuelve los puntos.

Quien lo recibe lo ve en **Para ti**, arriba del todo de la pantalla de
tareas, con el motivo escrito tal cual y cuántos puntos se mueven. Se quita
dándole a *Vale* (`seen = true`). Ahí salen también los canjes aprobados.

Si la persona está en la lista de la compra en vez de en tareas, le aparece un
aviso rojo arriba que la lleva a la sección.

**Antes de usarlo hay que correr `supabase-migracion-4.sql`.**

## 7. Pruebas con foto

Cada tarea tiene, al lado de *Hecho*, un botón de cámara. Abre una ventana con
dos huecos, **Antes** y **Después**, y marca la tarea como hecha igual que el
botón normal.

Son **opcionales**: los dos huecos, o solo uno, o ninguno. La idea es que estén
ahí para cuando alguien dude, no que haya que fotografiarlo todo.

Las fotos que se suban salen en el historial con un botón de cámara para
verlas a tamaño completo.

**Antes de usarlo hay que correr `supabase-migracion-3.sql`**, que añade las
columnas y crea el almacén de fotos.

Detalles de implementación:

- Una foto de móvil son 3-5 MB. Antes de subirla, `compress()` la reduce a
  900px de lado mayor y JPEG al 72% con un canvas: quedan unos 100 KB. Con el
  1 GB del plan gratis caben del orden de diez mil.
- En la tabla `logs` solo se guarda la URL (`photo_before`, `photo_after`).
  El archivo vive en el bucket `pruebas` de Supabase Storage.
- El bucket es **público**: cualquiera con la URL exacta de una foto la puede
  ver. Las URLs llevan un nombre aleatorio y no hay listado, pero no es un
  sitio para fotos que importen.
- Se puede subir, no borrar. Así nadie tapa su rastro; para limpiar, el panel
  de Supabase.
- En modo local (sin Supabase) la foto se guarda como data URL dentro del
  navegador, comprimida más fuerte. El navegador solo da unos 5 MB, así que
  eso es para probar, no para usar.

---

## Cómo funciona por dentro

- **Una sola capa de datos** (`State.store`) con dos implementaciones,
  `LocalStore` y `SupaStore`, con la misma API (`load`, `insert`, `update`,
  `remove`, `onChange`). Cambiar de una a otra es sólo rellenar las dos
  constantes.
- **Dos contadores, no uno.** El **saldo** (`logs` menos `redemptions`) es lo
  que te queda por gastar y baja al canjear. Los **puntos del mes**
  (`earnedIn`) solo suman lo ganado en el mes que corre y **no bajan al
  canjear**, así que quien gasta sus puntos no se queda fuera del ranking.
- **El reinicio mensual no reinicia nada.** Los puntos del mes se calculan
  filtrando `logs` por fecha, así que el 1 de cada mes el marcador vuelve a
  cero solo. No hay proceso programado que pueda fallar, y el histórico sigue
  entero: la sección *Meses anteriores* saca de ahí quién ganó cada mes.
- **Puntos calculados, no guardados**: ningún total vive en una columna, así
  que dos móviles escribiendo a la vez no pueden descuadrar el marcador.
- **Categorías automáticas**: `guessCat()` clasifica "tomates" en *Fresco* y
  "fairy" en *Limpieza* con un diccionario de palabras. Amplíalo en
  `KEYWORDS`.
- **Cantidades**: `parseEntry()` entiende "6 huevos", "2kg patatas" y
  "leche x2" y separa la cantidad del producto.
- **Modo súper**: agranda los toques, esconde quién añadió qué y quita las
  cabeceras de categoría, para ir tachando con el carro en la mano.
- **Filtro por quién lo pidió**: chips encima de la lista, con el número de
  cosas de cada uno. Solo aparecen si hay más de una persona con cosas
  pendientes, y se esconden en modo súper (en el súper interesa la lista
  entera). *Vaciar* respeta el filtro, y si escribes algo mientras miras la
  lista de otro, el filtro se quita solo para que veas lo que acabas de poner.

## Ideas para después

- Productos recurrentes: "esto lo compramos cada semana" → se repone solo.
- Historial de precios y gasto por compra.
- Notificación push cuando alguien añade algo a la lista.
- Racha semanal de tareas (bonus por completar X días seguidos).
- Un tercer NFC en la entrada con recados y avisos.
