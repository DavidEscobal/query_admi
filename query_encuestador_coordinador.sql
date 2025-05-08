use onu_mujeres;
-- ver perfil
SELECT 
    concat(u.nombre,' ',u.apellido_paterno,' ',u.apellido_materno) as "nombre completo",
    u.dni,
    u.correo,
    u.direccion,
    u.codigo_unico_encuestador,
    u.estado,
    u.fecha_registro,
    u.ultima_conexion,
    d.nombre AS nombre_distrito,
    z.nombre AS nombre_zona,
    r.nombre AS rol
FROM 
    usuarios u
INNER JOIN distritos d ON u.distrito_id = d.distrito_id
INNER JOIN zonas z ON u.zona_id = z.zona_id
INNER JOIN roles r ON u.rol_id = r.rol_id
WHERE 
    u.usuario_id = 7
    AND r.nombre = 'encuestador';
--
	
	
-- ver formularios con contador de borradores y llenados
	
-- Formularios sin llenar
SELECT e.encuesta_id, e.nombre, e.descripcion
FROM encuestas_asignadas ea
INNER JOIN encuestas e ON ea.encuesta_id = e.encuesta_id
LEFT JOIN respuestas r ON e.encuesta_id = r.encuesta_id AND r.encuestador_id = ea.encuestador_id
WHERE ea.encuestador_id = 7 AND ea.estado = 'activo' AND r.respuesta_id IS NULL;

-- Formularios con borradores
SELECT e.encuesta_id, e.nombre, COUNT(r.respuesta_id) AS borradores
FROM encuestas_asignadas ea
INNER JOIN encuestas e ON ea.encuesta_id = e.encuesta_id
INNER JOIN respuestas r ON e.encuesta_id = r.encuesta_id AND r.encuestador_id = ea.encuestador_id
WHERE ea.encuestador_id = 7 AND ea.estado = 'activo' AND r.estado = 'borrador'
GROUP BY e.encuesta_id, e.nombre;

-- Formularios completados
SELECT e.encuesta_id, e.nombre, COUNT(r.respuesta_id) AS completadas
FROM encuestas_asignadas ea
INNER JOIN encuestas e ON ea.encuesta_id = e.encuesta_id
INNER JOIN respuestas r ON e.encuesta_id = r.encuesta_id AND r.encuestador_id = ea.encuestador_id
WHERE ea.encuestador_id = 7 AND ea.estado = 'activo' AND r.estado = 'completo'
GROUP BY e.encuesta_id, e.nombre;
--
	
	
--cantidad de respuestas

SELECT 
    e.encuesta_id,
    e.nombre AS nombre_encuesta,
    COUNT(r.respuesta_id) AS total_respuestas,
    SUM(CASE WHEN r.estado = 'completo' THEN 1 ELSE 0 END) AS respuestas_completas,
    SUM(CASE WHEN r.estado = 'borrador' THEN 1 ELSE 0 END) AS respuestas_borrador
FROM 
    respuestas r
RIGHT JOIN 
    (SELECT ea.encuesta_id, e.nombre 
     FROM encuestas_asignadas ea
     INNER JOIN encuestas e ON ea.encuesta_id = e.encuesta_id
     WHERE ea.encuestador_id = 7 AND ea.estado = 'activo') e
ON r.encuesta_id = e.encuesta_id AND r.encuestador_id = 7
GROUP BY 
    e.encuesta_id, e.nombre
ORDER BY 
    e.nombre;
--

--ver pregunta de cuestionario asignado
SELECT 
    bp.pregunta_id,
    bp.texto AS pregunta,
    bp.tipo,
    po.opcion_id,
    po.texto_opcion,
    po.valor,
    po.orden AS orden_opcion,
    pe.orden AS orden_pregunta
FROM 
    encuestas_asignadas ea
INNER JOIN 
    preguntas_encuesta pe ON ea.encuesta_id = pe.encuesta_id
INNER JOIN 
    banco_preguntas bp ON pe.pregunta_id = bp.pregunta_id
LEFT JOIN 
    pregunta_opciones po ON bp.pregunta_id = po.pregunta_id
WHERE 
    ea.encuestador_id = 7
    AND ea.encuesta_id = 1
    AND ea.estado = 'activo'
ORDER BY 
    pe.orden, po.orden;
--

--perfil coordinador

SELECT 
    concat(u.nombre,' ',u.apellido_paterno,' ',u.apellido_materno) as "nombre completo",
    u.dni,
    u.correo,
    u.direccion,
    u.estado,
    u.fecha_registro,
    u.ultima_conexion,
    z.zona_id,
    z.nombre AS nombre_zona,
    r.nombre AS rol,
    d.nombre AS nombre_distrito
FROM 
    usuarios u
INNER JOIN zonas z ON u.zona_id = z.zona_id
INNER JOIN roles r ON u.rol_id = r.rol_id
INNER JOIN distritos d ON u.distrito_id = d.distrito_id
WHERE 
    u.usuario_id = 3
    AND r.nombre = 'coordinador';
	
--

--encuestadores a su cargo(de su zona)
SELECT 
    u.usuario_id,
    u.nombre,
    u.apellido_paterno,
    u.apellido_materno,
    u.dni,
    u.correo,
    u.estado,
    d.nombre AS distrito,
    u.codigo_unico_encuestador
FROM 
    usuarios u
INNER JOIN distritos d ON u.distrito_id = d.distrito_id
INNER JOIN roles r ON u.rol_id = r.rol_id
WHERE 
    u.zona_id = (SELECT zona_id FROM usuarios WHERE usuario_id = 3)  -- Zona del coordinador
    AND r.nombre = 'encuestador'
ORDER BY 
    u.nombre;
--



-- ver encuestas que pertenecen a la zona del coordinador asignados a sus encuestadores(con cantidad de asignadas y las respondidas(en total por encuestados)
SELECT 
    e.encuesta_id,
    e.nombre,
    e.descripcion,
    e.carpeta,
    e.estado,
    COUNT(DISTINCT ea.encuestador_id) AS encuestadores_asignados,
    COUNT(DISTINCT r.respuesta_id) AS respuestas_totales
FROM 
    encuestas e
INNER JOIN encuestas_asignadas ea ON e.encuesta_id = ea.encuesta_id
LEFT JOIN respuestas r ON e.encuesta_id = r.encuesta_id AND r.estado = 'completo'
WHERE 
    ea.coordinador_id = 3  -- ID del coordinador
GROUP BY 
    e.encuesta_id
ORDER BY 
    e.carpeta, e.nombre;
	
--

-- ver cantida de respuesta completadas por encuestador de la zona
SELECT 
    u.usuario_id,
    CONCAT(u.nombre, ' ', u.apellido_paterno) AS encuestador,
    d.nombre AS distrito,
    COUNT(r.respuesta_id) AS respuestas_completas
FROM 
    usuarios u
INNER JOIN distritos d ON u.distrito_id = d.distrito_id
LEFT JOIN respuestas r ON u.usuario_id = r.encuestador_id AND r.estado = 'completo'
WHERE 
    u.zona_id = (SELECT zona_id FROM usuarios WHERE usuario_id = 3)  -- Zona del coordinador
    AND u.rol_id = (SELECT rol_id FROM roles WHERE nombre = 'encuestador')
GROUP BY 
    u.usuario_id
ORDER BY 
    respuestas_completas DESC;
	
-- ver cantidad de respuestas completadas por distrito de la zona del coordinador
SELECT 
    d.distrito_id,
    d.nombre AS distrito,
    COUNT(r.respuesta_id) AS respuestas_completas
FROM 
    distritos d
LEFT JOIN usuarios u ON d.distrito_id = u.distrito_id
LEFT JOIN respuestas r ON u.usuario_id = r.encuestador_id AND r.estado = 'completo'
WHERE 
    d.zona_id = (SELECT zona_id FROM usuarios WHERE usuario_id = 3)  -- Zona del coordinador
GROUP BY 
    d.distrito_id
ORDER BY 
    respuestas_completas DESC;
	
-- ver cantidad por zonas

SELECT 
    z.zona_id,
    z.nombre AS zona,
    COUNT(r.respuesta_id) AS respuestas_completas
FROM 
    zonas z
LEFT JOIN distritos d ON z.zona_id = d.zona_id
LEFT JOIN usuarios u ON d.distrito_id = u.distrito_id
LEFT JOIN respuestas r ON u.usuario_id = r.encuestador_id AND r.estado = 'completo'
GROUP BY 
    z.zona_id
ORDER BY 
    respuestas_completas DESC;
	
	
	
	
	
--dashboard para admin
SELECT 
    -- Resumen de usuarios
    (SELECT COUNT(*) FROM usuarios WHERE rol_id = (SELECT rol_id FROM roles WHERE nombre = 'administrador')) AS total_administradores,
    (SELECT COUNT(*) FROM usuarios WHERE rol_id = (SELECT rol_id FROM roles WHERE nombre = 'coordinador')) AS total_coordinadores,
    (SELECT COUNT(*) FROM usuarios WHERE rol_id = (SELECT rol_id FROM roles WHERE nombre = 'encuestador')) AS total_encuestadores,
    
    -- Actividad reciente
    (SELECT COUNT(*) FROM respuestas WHERE fecha_envio >= CURDATE() - INTERVAL 7 DAY) AS respuestas_ultima_semana,
    
    -- Distribución geográfica
    (SELECT COUNT(DISTINCT dni_encuestado) FROM respuestas r JOIN usuarios u ON r.encuestador_id = u.usuario_id JOIN zonas z ON u.zona_id = z.zona_id WHERE z.nombre = 'Norte') AS encuestados_zona_norte,
    (SELECT COUNT(DISTINCT dni_encuestado) FROM respuestas r JOIN usuarios u ON r.encuestador_id = u.usuario_id JOIN zonas z ON u.zona_id = z.zona_id WHERE z.nombre = 'Sur') AS encuestados_zona_sur,
    
    -- Estado de usuarios
    (SELECT COUNT(*) FROM usuarios WHERE estado = 'activo') AS usuarios_activos,
    (SELECT COUNT(*) FROM usuarios WHERE estado = 'inactivo') AS usuarios_inactivos,
    (SELECT COUNT(*) FROM usuarios WHERE estado = 'baneado') AS usuarios_baneados,
    
    -- Última actualización
    NOW() AS ultima_actualizacion;


--ver usuarios
SELECT 
    u.usuario_id,
    u.nombre,
    u.apellido_paterno,
    u.apellido_materno,
    u.dni,
    u.correo,
    u.estado,
    r.nombre AS rol,
    CASE
        WHEN r.nombre = 'coordinador' THEN '--'
        WHEN r.nombre = 'administrador' THEN '--'
        ELSE d.nombre
    END AS distrito_asignado,
    CASE
        WHEN r.nombre = 'administrador' THEN '--'
        ELSE z.nombre
    END AS zona_asignada,
    CASE
        WHEN r.nombre = 'encuestador' THEN (
            SELECT CONCAT(c.nombre, ' ', c.apellido_paterno)
            FROM usuarios c
            WHERE c.zona_id = u.zona_id AND c.rol_id = (SELECT rol_id FROM roles WHERE nombre = 'coordinador')
            LIMIT 1
        )
        ELSE '--'
    END AS coordinador_asignado,
    CASE
        WHEN r.nombre = 'encuestador' THEN (
            SELECT c.estado
            FROM usuarios c
            WHERE c.zona_id = u.zona_id AND c.rol_id = (SELECT rol_id FROM roles WHERE nombre = 'coordinador')
            LIMIT 1
        )
        ELSE '--'
    END AS estado_coordinador,
    u.fecha_registro,
    u.ultima_conexion
FROM 
    usuarios u
INNER JOIN roles r ON u.rol_id = r.rol_id
LEFT JOIN distritos d ON u.distrito_id = d.distrito_id
LEFT JOIN zonas z ON u.zona_id = z.zona_id

ORDER BY 
    CASE r.nombre
        WHEN 'administrador' THEN 1
        WHEN 'coordinador' THEN 2
        WHEN 'encuestador' THEN 3
    END,
    u.nombre;
	
-- ver coordinador

SELECT 
    u.usuario_id,
    u.nombre,
    u.apellido_paterno,
    u.apellido_materno,
    u.dni,
    u.correo,
    u.estado,
    z.nombre AS zona_asignada,
    d.nombre AS distrito_referencia,
    u.fecha_registro,
    u.ultima_conexion,
    COUNT(DISTINCT ea.encuesta_id) AS encuestas_asignadas,
    COUNT(DISTINCT e.usuario_id) AS encuestadores_asignados
FROM 
    usuarios u
LEFT JOIN zonas z ON u.zona_id = z.zona_id
LEFT JOIN distritos d ON u.distrito_id = d.distrito_id
LEFT JOIN encuestas_asignadas ea ON u.usuario_id = ea.coordinador_id
LEFT JOIN usuarios e ON e.zona_id = u.zona_id AND e.rol_id = (SELECT rol_id FROM roles WHERE nombre = 'encuestador')
WHERE 
    u.rol_id = (SELECT rol_id FROM roles WHERE nombre = 'coordinador')
GROUP BY 
    u.usuario_id
ORDER BY 
    z.nombre, u.nombre;
	
-- ver encuestadores

SELECT 
    e.usuario_id,
    e.nombre,
    e.apellido_paterno,
    d.nombre AS distrito,
    z.nombre AS zona,
    CONCAT(c.nombre, ' ', c.apellido_paterno) AS coordinador_asignado,
    (
        SELECT COUNT(*) 
        FROM respuestas r 
        WHERE r.encuestador_id = e.usuario_id 
        AND r.estado = 'completo'
    ) AS respuestas_completas
FROM 
    usuarios e
INNER JOIN distritos d ON e.distrito_id = d.distrito_id
INNER JOIN zonas z ON d.zona_id = z.zona_id
INNER JOIN usuarios c ON z.zona_id = c.zona_id 
    AND c.rol_id = (SELECT rol_id FROM roles WHERE nombre = 'coordinador')
WHERE 
    e.rol_id = (SELECT rol_id FROM roles WHERE nombre = 'encuestador')
ORDER BY 
    z.nombre, d.nombre, e.nombre;