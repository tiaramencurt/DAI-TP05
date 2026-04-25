# TRABAJO PRÁCTICO - SQL sobre la base DAI

El objetivo de este trabajo práctico es repasar la sintaxis de SQL Server haciendo consultas sobre la base de datos `DAI`, que modela una **plataforma de beneficios y descuentos** (comercios que ofrecen beneficios a usuarios que los canjean).

## Modelo de datos

![Diagrama de la base DAI](schema.jpg)

La base `DAI` tiene 5 tablas:

| Tabla | Columnas (tipo) |
|---|---|
| **`provincias`** | `id` *(int, PK, IDENTITY)* · `nombre` *(varchar 150, NOT NULL)* · `orden` *(int)* · `activo` *(bit)* |
| **`usuarios`** | `id` *(int, PK, IDENTITY)* · `nombre` *(varchar 75, NOT NULL)* · `apellido` *(varchar 75)* · `fecha_nacimiento` *(date)* · `id_provincia` *(int, FK → provincias.id)* |
| **`comercios`** | `id` *(int, PK, IDENTITY)* · `nombre` *(varchar 150, NOT NULL)* · `descripcion` *(varchar max)* · `telefono_principal` *(varchar 75)* · `Comercio_DatosContacto` *(varchar 150)* · `url` *(varchar 512)* · `email` *(varchar 320)* · `activo` *(bit)* |
| **`beneficios`** | `id` *(int, PK, IDENTITY)* · `nombre` *(varchar 150, NOT NULL)* · `id_comercio` *(int, FK → comercios.id)* · `descripcion_corta` *(varchar 150)* · `descuento` *(smallint)* · `activo` *(bit)* |
| **`beneficios_usuarios`** | `id` *(int, PK, IDENTITY)* · `id_beneficio` *(int, NOT NULL, FK → beneficios.id)* · `id_usuario` *(int, NOT NULL, FK → usuarios.id)* · `fecha` *(datetime, NOT NULL)* — *registra cada vez que un usuario canjeó un beneficio* |

Relaciones:

```
provincias ──< usuarios ──< beneficios_usuarios >── beneficios >── comercios
```

### Coherencia del schema

Cuando mires la tabla de arriba, fijate que el diseño es **coherente**. No son detalles menores: un schema coherente se lee y se mantiene mucho más fácil.

- **Nombres de columnas en minúsculas y en español.** Todas las tablas siguen la misma convención: `id`, `nombre`, `activo`, `fecha`, `id_xxx` para FKs. Nada de mezclar idiomas (`name` vs `nombre`) ni estilos (`Id` vs `id` vs `ID`).
- **Claves primarias siempre iguales.** Las 5 tablas tienen una PK llamada `id`, tipo `int`, con `IDENTITY(1,1)` y `NOT NULL`. Saber esto de memoria agiliza escribir JOINs: no hay que ir a mirar cómo se llama la PK en cada tabla.
- **Claves foráneas con nombre predecible.** Siempre `id_<tabla_referenciada_en_singular>` (`id_comercio`, `id_usuario`, `id_provincia`, `id_beneficio`). Con solo ver el nombre ya sabés a qué tabla apunta.
- **Tipos y largos consistentes según el significado.**
  - Nombres cortos de personas → `varchar(75)` (`usuarios.nombre`, `usuarios.apellido`).
  - Nombres de entidades/catálogos → `varchar(150)` (`provincias.nombre`, `comercios.nombre`, `beneficios.nombre`, `descripcion_corta`).
  - Descripciones largas → `varchar(max)` (`comercios.descripcion`).
  - URLs → `varchar(512)` y emails → `varchar(320)` (alineado con los máximos del estándar).
  - Flags booleanos → `bit` con nombre `activo` en todas las tablas.
- **Tipos numéricos al tamaño justo.** `descuento` es `smallint` porque un porcentaje nunca necesita un `int`; los `id` sí son `int` porque pueden crecer mucho.
- **Fechas con el tipo apropiado.** `fecha_nacimiento` es `date` (no importa la hora). `beneficios_usuarios.fecha` es `datetime` (sí importa el momento exacto del canje).
- **Reglas de nulabilidad con criterio.** Lo que **identifica** la fila o es **imprescindible** es `NOT NULL` (todos los `id`, los `nombre`, las FKs de la tabla de canjes). Lo que puede faltar al momento de la carga queda `NULL` (apellido, fecha de nacimiento, email, teléfono).

> 💡 **Por qué importa esto.** En bases reales, los equipos que trabajan sobre un schema coherente se equivocan menos, escriben consultas más rápido y los bugs son más fáciles de encontrar. Cuando veas un schema donde cada tabla tiene su propia "personalidad" (una PK `Id`, otra `IDUSUARIO`, otra `usuario_pk`...), sabés que vas a sufrir.

## Formato de las consultas

Escribí tus consultas con cada cláusula en su propia línea, así se leen más fácil y se ven claramente los bloques de la consulta:

```sql
SELECT
    campo,
    campo
FROM tabla
INNER JOIN otra_tabla ON condicion
WHERE condicion
AND   otra_condicion
GROUP BY
    campo
HAVING condicion
ORDER BY
    campo ASC,
    campo DESC
```

> 💡 Al lado de cada ejercicio vas a ver entre paréntesis la **cantidad de filas** que debería devolver tu consulta. Úsalo para verificar que tu respuesta es correcta.

---

## Nivel 1 — SELECT, ORDER BY, alias, CONCAT

### 1. Obtener todos los datos de todos los usuarios. (filas 228)

**Cómo pensarla:** `SELECT *` trae **todas las columnas** de la tabla. Es lo más básico: sirve para ver rápido qué hay en una tabla cuando estamos explorando.

> ⚠️ **Por qué `*` es peligroso en código "de verdad"**
>
> - **El motor no se ahorra trabajo: se lo agrega.** Antes de ejecutar la consulta, SQL Server tiene que ir al catálogo de la base, averiguar cuáles son **todas** las columnas de la tabla, en qué orden están definidas, y recién ahí armar el resultado. Si vos escribís `nombre, apellido`, el motor sabe directamente qué traer y en qué orden.
> - **No sabés el orden en que te las va a devolver.** Si alguien agrega una columna nueva a la tabla, o si alguien reordena las columnas, tu consulta sigue funcionando pero los **resultados cambian de lugar**. Si tu código depende de "la tercera columna" (por ejemplo, leyéndola desde una aplicación), se rompe todo sin que te des cuenta.
> - **Traés información que no necesitás.** La tabla `comercios` tiene un campo `descripcion` de tipo `varchar(max)` que puede ocupar kilobytes por fila. Con `SELECT *` viaja por la red aunque no lo uses.
> - **Cuando listás las columnas (`col, col, col`) sabés exactamente qué llega y en qué posición.** Se trae **lo justo y necesario**, el orden es el que vos definiste, y si mañana alguien toca la tabla tu consulta sigue devolviendo lo mismo.
>
> Regla práctica: `SELECT *` está bien **solo para explorar** a mano en SSMS. En cualquier consulta que quede escrita en un script, en una aplicación o en un reporte, siempre listá las columnas.

---

### 2. Obtener el nombre y el apellido de todos los usuarios. (filas 228)

**Cómo pensarla:** en lugar de `*` listamos **solo las columnas** que nos interesan, separadas por coma. Trae la misma cantidad de filas que el ejercicio 1, pero con menos columnas.

---

### 3. Obtener nombre y apellido de todos los usuarios, ordenados por apellido. (filas 228)

**Cómo pensarla:** `ORDER BY` ordena el resultado. Por defecto es **ascendente** (A-Z, 0-9). Si quisiera al revés escribiría `DESC`.

---

### 4. Obtener apellido y nombre, ordenados primero por apellido y después por nombre (ORDER BY compuesto). (filas 228)

**Cómo pensarla:** cuando dos usuarios tienen el **mismo apellido**, el segundo criterio (`nombre`) decide el orden. Es como ordenar una lista de clase: primero por apellido y, si hay dos "García", alfabéticamente por nombre.

---

### 5. Obtener el nombre completo de cada usuario como una sola columna llamada `nombre_completo`, ordenado por apellido. (filas 228)

**Cómo pensarla:** `CONCAT` pega textos. `AS` le pone un **alias** (un nombre nuevo) a la columna resultante. El `, ` (coma + espacio) es un texto fijo que se inserta entre apellido y nombre.

> 💡 **¿Por qué `CONCAT` y no `apellido + ', ' + nombre`?**
>
> En SQL Server se puede concatenar con el operador `+`, y muchas veces vas a ver código así:
>
> ```sql
> SELECT apellido + ', ' + nombre AS nombre_completo FROM usuarios
> ```
>
> Funciona... hasta que hay un **NULL**. En nuestra tabla `usuarios`, el campo `apellido` acepta `NULL`. Y ahí aparece la trampa:
>
> - **Con `+`:** `NULL + ', ' + 'Juan'` → **`NULL`**. La regla de SQL es que cualquier operación aritmética (y el `+` es un operador) con `NULL` **devuelve `NULL`**. Es decir, un usuario al que le falte el apellido te aparece con la columna entera vacía (ni siquiera ves el nombre).
> - **Con `CONCAT`:** `CONCAT(NULL, ', ', 'Juan')` → **`', Juan'`**. La función `CONCAT` **ignora los `NULL`** y los trata como cadena vacía. Nunca devuelve `NULL` (salvo que TODOS los argumentos sean `NULL`).
>
> Otras ventajas de `CONCAT`:
> - **Convierte tipos automáticamente.** `CONCAT('Edad: ', 17)` funciona; `'Edad: ' + 17` da error de conversión porque SQL Server trata de sumar el número `17` al texto.
> - **Se lee mejor cuando hay muchos campos.** `CONCAT(calle, ' ', numero, ', ', ciudad, ' (', cp, ')')` queda más claro que ir intercalando `+` entre comillas.
>
> Regla práctica: en SQL Server, **usá `CONCAT` siempre que estés juntando textos**. Evita el bug silencioso de los `NULL` y te saca varios problemas de conversión de tipos.

---

### 6. Obtener el nombre de los usuarios **sin repetidos**, ordenado alfabéticamente. (filas 192)

**Cómo pensarla:** `DISTINCT` elimina duplicados. Si hay tres "Juan" en la tabla, aparece una sola vez.

---

### 7. Obtener los primeros 10 usuarios ordenados por apellido. (filas 10)

**Cómo pensarla:** `TOP N` limita la cantidad de filas que devuelve la consulta. En SQL Server va **pegado al SELECT**, antes de las columnas. Combinarlo con `ORDER BY` es fundamental; sin orden, "los primeros 10" es un concepto ambiguo.

---

### 8. Obtener el nombre y apellido de los usuarios junto con el largo de su nombre (columna `largo_nombre`), ordenado por largo descendente. (filas 228)

**Cómo pensarla:** `LEN` devuelve la cantidad de caracteres de un texto. Podemos usar el **alias** en el `ORDER BY`. `DESC` ordena de mayor a menor.

---

## Nivel 2 — WHERE, AND, OR, LIKE, IN

### 9. Obtener todos los beneficios que están activos. (filas 25)

**Cómo pensarla:** `WHERE` filtra filas. `activo` es de tipo `bit`, entonces `1` = verdadero y `0` = falso.

---

### 10. Obtener los beneficios activos **Y** con descuento mayor o igual a 20. (filas 19)

**Cómo pensarla:** `AND` pide que se cumplan **las dos condiciones a la vez**. Si una falla, la fila se descarta.

---

### 11. Obtener los beneficios cuyo descuento sea menor a 10 **O** mayor a 50. (filas 2)

**Cómo pensarla:** `OR` pide que se cumpla **al menos una** de las condiciones. En este caso queremos los "extremos" de descuento.

---

### 12. Obtener los comercios cuyo nombre **empiece con** 'M'. (filas 125)

**Cómo pensarla:** `LIKE` se usa para buscar patrones en textos. El `%` es un comodín que significa "cualquier cosa". `'M%'` = empieza con M y después cualquier cosa.

---

### 13. Obtener los comercios cuyo nombre **termine con** 'SA'. (filas 13)

**Cómo pensarla:** mismo comodín `%`, pero ahora al principio. `'%SA'` = cualquier cosa que termine con SA.

---

### 14. Obtener los comercios cuyo nombre **contenga** la palabra 'super' (en cualquier parte). (filas 3)

**Cómo pensarla:** `%` a los dos lados significa "cualquier cosa antes y después". Es el patrón más usado para búsquedas tipo "contiene".

---

### 15. Obtener los usuarios cuya **segunda letra** del nombre sea una 'a'. (filas 63)

**Cómo pensarla:** `_` (guión bajo) es otro comodín de `LIKE`: significa **exactamente un carácter cualquiera**. `'_a%'` = un carácter, después una 'a', después lo que sea.

---

### 16. Obtener los usuarios cuyo apellido sea 'Gonzalez', 'Ruiz' o 'Gomez'. (filas 8)

**Cómo pensarla:** `IN` es una forma corta de escribir varios `OR`. Es equivalente a `apellido = 'García' OR apellido = 'Pérez' OR apellido = 'Gómez'`, pero mucho más legible.

---

### 17. Obtener los usuarios cuyo apellido **NO** sea 'Gonzalez', 'Ruiz' ni 'Gomez'. (filas 220)

**Cómo pensarla:** `NOT IN` es la negación de `IN`. ⚠️ Ojo: si el apellido es `NULL`, la fila **no aparece** porque `NULL` no se compara con nada con los operadores normales.

---

### 18. Obtener los beneficios de los comercios activos (usando subconsulta con IN). (filas 274)

**Cómo pensarla:** la **subconsulta** (la de adentro) devuelve una lista de `id` de comercios activos. Después el `IN` de afuera compara contra esa lista. Es como hacer una pregunta que usa la respuesta de otra pregunta.

---

### 19. Obtener la misma lista que en el ejercicio 18, pero **sin repetir** combinaciones de `nombre` y `descuento`. (filas 197)

**Cómo pensarla:** el ejercicio 18 devuelve **una fila por cada beneficio**. Si dos beneficios distintos tienen el mismo nombre y el mismo descuento (por ejemplo, dos sucursales del mismo comercio cargaron el beneficio "2x1 en café" con 50%), aparecen repetidos en el resultado. `DISTINCT` mira el conjunto de columnas seleccionadas y **elimina las filas duplicadas**.

> 💡 **`DISTINCT` mira todas las columnas del SELECT a la vez, no una sola.** Si agregáramos `id_comercio` al SELECT, dos beneficios con el mismo nombre pero distinto comercio ya contarían como "distintos" y volverían a aparecer. Por eso el resultado de `DISTINCT` depende mucho de **qué columnas elegiste mostrar**.
>
> ⚠️ **Ojo: `DISTINCT` no es gratis.** Para quitar duplicados el motor tiene que **ordenar u hashear** todas las filas y compararlas. En tablas chicas no se nota, pero abusar de `DISTINCT` para "tapar" problemas de una consulta mal armada (por ejemplo, un JOIN que multiplica filas) es un antipatrón clásico: si te aparecen duplicados inesperados, primero entendé **por qué** están duplicados y después decidí si `DISTINCT` es la solución correcta o si hay que arreglar la consulta.

---

### 20. Obtener los beneficios que **NO** pertenecen a comercios activos. (filas 21)

**Cómo pensarla:** misma idea que el anterior pero con `NOT IN`. Muy útil para encontrar "los que no están en la otra tabla / en la otra lista".

---

### 21. Obtener los 5 beneficios con **mayor descuento**. (filas 5)

**Cómo pensarla:** combinamos `TOP` con `ORDER BY DESC` para quedarnos con los que están arriba del ranking.

---

## Nivel 3 — Fechas (DATEDIFF, DATEADD, YEAR, MONTH)

### 22. Obtener los usuarios que nacieron en el año 1981. (filas 6)

**Cómo pensarla:** `YEAR()` extrae el año de una fecha. Después lo comparamos con un número entero.

---

### 23. Obtener los usuarios que cumplen años en el mes de **mayo**. (filas 20)

**Cómo pensarla:** `MONTH()` devuelve el número de mes (1-12). Mayo = 5. `DAY()` devuelve el día del mes.

---

### 24. Obtener el nombre, apellido y la **edad** de cada usuario (columna `edad`), ordenado por edad descendente. (filas 228)

**Cómo pensarla:** `DATEDIFF(unidad, fecha1, fecha2)` calcula la diferencia entre dos fechas en la unidad indicada (`YEAR`, `MONTH`, `DAY`...). `GETDATE()` devuelve la fecha y hora actuales. ⚠️ Este cálculo de edad es **aproximado**: cuenta el año sin importar si ya pasó el cumpleaños.

---

### 25. Obtener los canjes de beneficios (`beneficios_usuarios`) realizados en los **últimos 30 días**. (filas 49)

**Cómo pensarla:** `DATEADD(unidad, cantidad, fecha)` suma (o resta, con cantidad negativa) tiempo a una fecha. Acá pedimos "la fecha de hoy menos 30 días" y filtramos los canjes posteriores a eso.

---

### 26. Obtener los canjes realizados **entre** el 1 de enero y el 31 de marzo de 2025. (filas 375)

**Cómo pensarla:** filtramos por rango. Es una buena práctica usar `>= inicio` y `< día siguiente al final` para evitar problemas con las horas del último día (si usáramos `<= '2025-03-31'` nos perderíamos los canjes del 31 de marzo a las 10 de la noche).

---

## Nivel 4 — NULL y NOT NULL

### 27. Obtener los usuarios que **NO tienen** fecha de nacimiento cargada. (filas 0)

**Cómo pensarla:** `NULL` significa "sin dato". **No se compara con `=`**, siempre se usa `IS NULL` o `IS NOT NULL`. Escribir `= NULL` nunca devuelve nada (aunque no da error).

---

### 28. Obtener los comercios que tienen **email cargado** (no nulo) y además están activos. (filas 109)

**Cómo pensarla:** `IS NOT NULL` es la contraparte de `IS NULL`. Combinado con otro filtro, con `AND`.

---

## Nivel 5 — Funciones de agregación (COUNT, SUM, MAX, MIN, AVG)

### 29. Contar cuántos usuarios hay en total. (filas 228)

**Cómo pensarla:** `COUNT(*)` cuenta **todas las filas**, incluidas las que tengan NULL. Es la forma más común de contar registros.

---

### 30. Contar cuántos usuarios tienen fecha de nacimiento cargada (y cuántos no). (filas 1)

**Cómo pensarla:** `COUNT(columna)` **NO cuenta los NULL** de esa columna. Esta es la diferencia clave con `COUNT(*)`. Restando los dos sabemos cuántos tienen valor nulo.

---

### 31. Obtener el descuento **máximo**, **mínimo** y **promedio** de los beneficios activos. (filas 1)

**Cómo pensarla:** `MAX`, `MIN` y `AVG` hacen lo que dicen. Cada una devuelve **una sola fila**. `AVG` sobre enteros devuelve un entero (trunca los decimales); si queremos precisión hay que hacer `AVG(CAST(descuento AS DECIMAL(10,2)))`.

---

## Nivel 6 — JOINS

### 32. Obtener el nombre del beneficio junto con el nombre del comercio que lo ofrece. (filas 295)

**Cómo pensarla:** un `INNER JOIN` combina filas de dos tablas cuando cumplen la condición (`ON`). Usamos **alias** cortos (`b`, `c`) para no repetir nombres largos. Solo aparecen beneficios que **sí** tienen comercio asociado.

---

### 33. Obtener nombre y apellido de cada usuario junto con el nombre de su provincia. (filas 200)

**Cómo pensarla:** mismo patrón que el anterior. Usuarios sin provincia asignada (`id_provincia IS NULL`) **no aparecen** porque es INNER JOIN.

---

### 34. Obtener **todos** los usuarios y, si tienen provincia, el nombre; si no, mostrar NULL. (filas 228)

**Cómo pensarla:** `LEFT JOIN` trae **todas las filas de la tabla de la izquierda** (`usuarios`), y rellena con `NULL` las columnas de la derecha cuando no hay coincidencia. Es el JOIN que se usa cuando querés "no perder filas" del lado principal.

---

### 35. Obtener **todas** las provincias y los usuarios que viven en ellas (aunque una provincia no tenga usuarios). (filas 219)

**Cómo pensarla:** `RIGHT JOIN` es el espejo de LEFT JOIN: conserva **todas las filas de la tabla de la derecha**. En la práctica se usa menos: se prefiere reescribirlo como LEFT JOIN invirtiendo el orden de las tablas.

> 💡 **Desafío extra:** resolvé el mismo ejercicio con `LEFT JOIN` en lugar de `RIGHT JOIN` (poniendo `provincias` a la izquierda del JOIN). Fijate que el resultado debe ser **idéntico**.

---

### 36. Obtener los usuarios que **nunca canjearon un beneficio** (usando LEFT JOIN). (filas 0)

**Cómo pensarla:** truco clásico: hacé `LEFT JOIN` y después filtrá por `IS NULL` en la tabla de la derecha. Si no hay match, la columna del lado derecho queda en NULL → esas son las filas "huérfanas".

> 💡 **Desafío extra:** resolvé la misma pregunta usando `NOT IN` con una subconsulta (sin JOIN). El resultado tiene que ser el mismo.
>
> ⚠️ **Cuidado con `NOT IN` cuando la columna puede ser `NULL`.** Si la subconsulta llega a devolver algún `NULL`, el `NOT IN` pasa a devolver **cero filas** (por la lógica ternaria de SQL: `x NOT IN (a, b, NULL)` nunca es verdadero). En este caso estamos a salvo porque `beneficios_usuarios.id_usuario` es `NOT NULL`, pero en otras consultas hay que verificarlo — es un bug silencioso muy común.

---

### 37. Obtener el nombre del usuario, nombre del beneficio, nombre del comercio y fecha del canje — triple JOIN. (filas 506)

**Cómo pensarla:** los JOIN se encadenan. Empezá por la tabla "central" (`beneficios_usuarios`, que tiene las FK a todo) y vas sumando las demás. El orden de los JOIN no cambia el resultado, pero sí la legibilidad.

---

## Nivel 7 — GROUP BY, HAVING, ISNULL

### 38. Nombre del comercio y cantidad de beneficios que ofrece, ordenado de mayor a menor. (filas 98)

**Cómo pensarla:** `GROUP BY` agrupa filas que tienen el mismo valor en las columnas indicadas y permite calcular agregaciones (COUNT, SUM, etc.) sobre cada grupo. Regla de oro: **toda columna del SELECT que NO esté dentro de una función de agregación, tiene que estar en el GROUP BY**.

---

### 39. Nombre del comercio y cantidad de beneficios que ofrece, pero solo los comercios que tienen **más de 3 beneficios**. (filas 25)

**Cómo pensarla:** `HAVING` es como el `WHERE`, pero se aplica **después del GROUP BY**, sobre las agregaciones. Regla práctica: si el filtro usa `COUNT`, `SUM`, `AVG`, etc., va en HAVING; si usa columnas "crudas", va en WHERE.

---

### 40. Nombre del comercio y suma total de descuentos de sus beneficios activos, ordenado de mayor a menor. (filas 16)

**Cómo pensarla:** `SUM` suma valores numéricos por grupo. El `WHERE` se aplica antes del GROUP BY para filtrar beneficios inactivos.

---

### 41. Nombre del comercio, descuento **promedio** y cantidad de beneficios, solo los comercios que tengan promedio mayor a 15. (filas 84)

**Cómo pensarla:** se pueden calcular varias agregaciones en el mismo SELECT. El HAVING filtra por el promedio calculado.

---

### 42. Nombre de la provincia y cantidad de **beneficios distintos canjeados** por los usuarios de esa provincia, ordenada de mayor a menor. (filas 6)

**Cómo pensarla:** hay que "viajar" por varias tablas: provincia → usuarios → canjes. Usamos `COUNT(DISTINCT ...)` porque un mismo beneficio puede aparecer muchas veces en `beneficios_usuarios` y queremos contar beneficios **únicos**, no canjes.

---

### 43. Nombre de la provincia y cantidad de **usuarios** que viven en ella, usando INNER JOIN (no aparecen provincias sin usuarios). (filas 6)

**Cómo pensarla:** JOIN clásico + GROUP BY. ⚠️ Una provincia que no tenga ningún usuario **no aparece en el resultado** — el INNER JOIN la descarta. Si la provincia de Tierra del Fuego no tiene usuarios, acá no figura.

---

### 44. Nombre de **TODAS** las provincias y cantidad de **usuarios** que viven en cada una, usando LEFT JOIN — las provincias sin usuarios aparecen con 0. (filas 25)

**Cómo pensarla:** este es el "compañero" del ejercicio anterior. Con `LEFT JOIN` desde `provincias`, **todas** las provincias aparecen. Cuando no hay usuarios, `COUNT(u.id)` da 0 (ojo: `COUNT(u.id)` ya cuenta 0 si no hay filas, pero se usa `ISNULL` cuando la función podría devolver NULL, por ejemplo con `SUM`). Es un patrón muy típico en reportes: "quiero ver TODAS las categorías, aunque estén en cero".

> 💡 **Comparar los dos resultados (43 vs 44)** es el ejercicio interesante: la diferencia en la cantidad de filas es la cantidad de provincias sin usuarios.

---

### 45. Top 5 comercios con **más canjes** de sus beneficios (mostrar nombre del comercio y cantidad de canjes). (filas 5)

**Cómo pensarla:** combina TOP + JOIN (triple) + GROUP BY + ORDER BY. Acá contamos filas de `beneficios_usuarios` (cada fila = un canje), no beneficios distintos.

---

### 46. Apellido, nombre y cantidad de beneficios canjeados de cada usuario (incluir usuarios que no canjearon nunca, mostrando 0). (filas 201)

**Cómo pensarla:** mismo patrón que el ejercicio 44 pero del lado usuarios. `LEFT JOIN` + `COUNT` para que los usuarios sin canjes aparezcan con 0. Todas las columnas del SELECT que no son agregadas (`apellido`, `nombre`) tienen que ir en el `GROUP BY`.

---

## Desafíos extra

### 47. Obtener el comercio con **mayor promedio de descuento** (mostrar nombre y promedio). (filas 1)

**Cómo pensarla:** `TOP 1` + `ORDER BY DESC` nos da "el que está primero en el ranking".

---

### 48. Nombre de la provincia, cantidad de usuarios y cantidad total de canjes que hicieron esos usuarios. (filas 25)

**Cómo pensarla:** cuidado con los `COUNT` cuando hay varios JOIN. `COUNT(DISTINCT u.id)` evita que un usuario con 10 canjes se cuente 10 veces como usuario. `COUNT(bu.id)` sí cuenta todas las filas de canjes.

---
