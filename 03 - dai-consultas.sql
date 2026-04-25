-- 1
SELECT *
FROM usuarios;

-- 2
SELECT nombre, apellido
FROM usuarios;

-- 3
SELECT nombre, apellido
FROM usuarios
ORDER BY apellido;

-- 4
SELECT apellido, nombre
FROM usuarios
ORDER BY apellido, nombre;

-- 5
SELECT CONCAT(apellido, ', ', nombre) AS nombre_completo
FROM usuarios
ORDER BY apellido;

-- 6
SELECT DISTINCT nombre
FROM usuarios
ORDER BY nombre;

-- 7
SELECT TOP 10 *
FROM usuarios
ORDER BY apellido;

-- 8
SELECT nombre, apellido, LEN(nombre) AS largo_nombre
FROM usuarios
ORDER BY largo_nombre DESC;

-- 9
SELECT *
FROM beneficios
WHERE activo = 1;

-- 10
SELECT *
FROM beneficios
WHERE activo = 1
AND descuento >= 20;

-- 11
SELECT *
FROM beneficios
WHERE descuento < 10
OR descuento > 50;

-- 12
SELECT *
FROM comercios
WHERE nombre LIKE 'M%';

-- 13
SELECT *
FROM comercios
WHERE nombre LIKE '%SA';

-- 14
SELECT *
FROM comercios
WHERE nombre LIKE '%super%';

-- 15
SELECT *
FROM usuarios
WHERE nombre LIKE '_a%';

-- 16
SELECT *
FROM usuarios
WHERE apellido IN ('Gonzalez', 'Ruiz', 'Gomez');

-- 17
SELECT *
FROM usuarios
WHERE apellido NOT IN ('Gonzalez', 'Ruiz', 'Gomez');

-- 18
SELECT *
FROM beneficios
WHERE id_comercio IN (
    SELECT id
    FROM comercios
    WHERE activo = 1
);

-- 19
SELECT DISTINCT nombre, descuento
FROM beneficios
WHERE id_comercio IN (
    SELECT id
    FROM comercios
    WHERE activo = 1
);

-- 20
SELECT *
FROM beneficios
WHERE id_comercio NOT IN (
    SELECT id
    FROM comercios
    WHERE activo = 1
);

-- 21
SELECT TOP 5 *
FROM beneficios
ORDER BY descuento DESC;

-- 22
SELECT *
FROM usuarios
WHERE YEAR(fecha_nacimiento) = 1981;

-- 23
SELECT *
FROM usuarios
WHERE MONTH(fecha_nacimiento) = 5;

-- 24
SELECT nombre, apellido,
       DATEDIFF(YEAR, fecha_nacimiento, GETDATE()) AS edad
FROM usuarios
ORDER BY edad DESC;

-- 25
SELECT *
FROM beneficios_usuarios
WHERE fecha >= DATEADD(DAY, -30, GETDATE());

-- 26
SELECT *
FROM beneficios_usuarios
WHERE fecha >= '2025-01-01'
AND fecha < '2025-04-01';

-- 27
SELECT *
FROM usuarios
WHERE fecha_nacimiento IS NULL;

-- 28
SELECT *
FROM comercios
WHERE email IS NOT NULL
AND activo = 1;

-- 29
SELECT COUNT(*) AS total_usuarios
FROM usuarios;

-- 30
SELECT COUNT(fecha_nacimiento) AS con_fecha,
       COUNT(*) - COUNT(fecha_nacimiento) AS sin_fecha
FROM usuarios;

-- 31
SELECT MAX(descuento) AS maximo,
       MIN(descuento) AS minimo,
       AVG(descuento) AS promedio
FROM beneficios
WHERE activo = 1;

-- 32
SELECT b.nombre AS beneficio,
       c.nombre AS comercio
FROM beneficios b
INNER JOIN comercios c ON b.id_comercio = c.id;

-- 33
SELECT u.nombre, u.apellido, p.nombre AS provincia
FROM usuarios u
INNER JOIN provincias p ON u.id_provincia = p.id;

-- 34
SELECT u.nombre, u.apellido, p.nombre AS provincia
FROM usuarios u
LEFT JOIN provincias p ON u.id_provincia = p.id;

-- 35
SELECT p.nombre AS provincia, u.nombre, u.apellido
FROM usuarios u
RIGHT JOIN provincias p ON u.id_provincia = p.id;

-- 36
SELECT u.*
FROM usuarios u
LEFT JOIN beneficios_usuarios bu ON u.id = bu.id_usuario
WHERE bu.id IS NULL;

-- 37
SELECT u.nombre,
       b.nombre AS beneficio,
       c.nombre AS comercio,
       bu.fecha
FROM beneficios_usuarios bu
INNER JOIN usuarios u ON bu.id_usuario = u.id
INNER JOIN beneficios b ON bu.id_beneficio = b.id
INNER JOIN comercios c ON b.id_comercio = c.id;

-- 38
SELECT c.nombre,
       COUNT(b.id) AS cantidad_beneficios
FROM comercios c
INNER JOIN beneficios b ON c.id = b.id_comercio
GROUP BY c.nombre
ORDER BY cantidad_beneficios DESC;

-- 39
SELECT c.nombre,
       COUNT(b.id) AS cantidad_beneficios
FROM comercios c
INNER JOIN beneficios b ON c.id = b.id_comercio
GROUP BY c.nombre
HAVING COUNT(b.id) > 3;

-- 40
SELECT c.nombre,
       SUM(b.descuento) AS total_descuento
FROM comercios c
INNER JOIN beneficios b ON c.id = b.id_comercio
WHERE b.activo = 1
GROUP BY c.nombre
ORDER BY total_descuento DESC;

-- 41
SELECT c.nombre,
       AVG(b.descuento) AS promedio,
       COUNT(b.id) AS cantidad
FROM comercios c
INNER JOIN beneficios b ON c.id = b.id_comercio
GROUP BY c.nombre
HAVING AVG(b.descuento) > 15;

-- 42
SELECT p.nombre,
       COUNT(DISTINCT bu.id_beneficio) AS cantidad
FROM provincias p
INNER JOIN usuarios u ON p.id = u.id_provincia
INNER JOIN beneficios_usuarios bu ON u.id = bu.id_usuario
GROUP BY p.nombre
ORDER BY cantidad DESC;

-- 43
SELECT p.nombre,
       COUNT(u.id) AS cantidad_usuarios
FROM provincias p
INNER JOIN usuarios u ON p.id = u.id_provincia
GROUP BY p.nombre;

-- 44
SELECT p.nombre,
       COUNT(u.id) AS cantidad_usuarios
FROM provincias p
LEFT JOIN usuarios u ON p.id = u.id_provincia
GROUP BY p.nombre;

-- 45
SELECT TOP 5 c.nombre,
       COUNT(bu.id) AS cantidad_canjes
FROM comercios c
INNER JOIN beneficios b ON c.id = b.id_comercio
INNER JOIN beneficios_usuarios bu ON b.id = bu.id_beneficio
GROUP BY c.nombre
ORDER BY cantidad_canjes DESC;

-- 46
SELECT u.apellido, u.nombre,
       COUNT(bu.id) AS cantidad_canjes
FROM usuarios u
LEFT JOIN beneficios_usuarios bu ON u.id = bu.id_usuario
GROUP BY u.apellido, u.nombre;

-- 47
SELECT TOP 1 c.nombre,
       AVG(b.descuento) AS promedio
FROM comercios c
INNER JOIN beneficios b ON c.id = b.id_comercio
GROUP BY c.nombre
ORDER BY promedio DESC;

-- 48
SELECT p.nombre,
       COUNT(DISTINCT u.id) AS cantidad_usuarios,
       COUNT(bu.id) AS total_canjes
FROM provincias p
LEFT JOIN usuarios u ON p.id = u.id_provincia
LEFT JOIN beneficios_usuarios bu ON u.id = bu.id_usuario
GROUP BY p.nombre;